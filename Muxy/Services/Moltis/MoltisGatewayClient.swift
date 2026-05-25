import Foundation
import os

private let gatewayLogger = Logger(subsystem: "app.muxy", category: "MoltisGatewayClient")

struct MoltisChatStreamEvent {
    enum Kind {
        case textDelta(String)
        case thinking
        case toolStart(name: String)
        case toolEnd(name: String, rejected: Bool)
        case final
        case notice(String)
    }

    let kind: Kind
}

actor MoltisGatewayClient {
    private var webSocket: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var nextRequestID = 1
    private var pending: [String: CheckedContinuation<MoltisProtocol.Response, Error>] = [:]
    private var eventContinuations: [UUID: AsyncStream<MoltisChatStreamEvent>.Continuation] = [:]
    private var activeRunID: String?

    func connect(port: Int) async throws {
        disconnect()
        guard let url = URL(string: "ws://127.0.0.1:\(port)/ws/chat") else {
            throw MoltisGatewayError.rpcFailed("Invalid gateway URL.")
        }
        let task = URLSession.shared.webSocketTask(with: url)
        webSocket = task
        task.resume()
        startReceiveLoop()
        _ = try await sendRequest(method: "connect", params: MoltisProtocol.connectParams())
        _ = try await sendRequest(method: "subscribe", params: MoltisProtocol.subscribeParams())
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        for (_, continuation) in pending {
            continuation.resume(throwing: CancellationError())
        }
        pending.removeAll()
        for (_, continuation) in eventContinuations {
            continuation.finish()
        }
        eventContinuations.removeAll()
        activeRunID = nil
    }

    func streamChat(
        message: String,
        sessionKey: String,
        contextPrefix: String?
    ) -> AsyncStream<MoltisChatStreamEvent> {
        let streamID = UUID()
        return AsyncStream { continuation in
            eventContinuations[streamID] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeStream(id: streamID) }
            }
            Task {
                do {
                    let response = try await self.sendRequest(
                        method: "chat.send",
                        params: MoltisProtocol.chatSendParams(
                            message: message,
                            sessionKey: sessionKey,
                            contextPrefix: contextPrefix
                        )
                    )
                    guard response.ok == true else {
                        throw MoltisGatewayError.rpcFailed(response.errorMessage ?? "chat.send failed")
                    }
                    await self.setActiveRunID(response.runID)
                } catch {
                    continuation.yield(MoltisChatStreamEvent(kind: .notice("**Error:** \(error.localizedDescription)")))
                    continuation.finish()
                    await self.removeStream(id: streamID)
                }
            }
        }
    }

    func abortActiveRun() async {
        guard let runID = activeRunID else { return }
        _ = try? await sendRequest(
            method: "chat.abort",
            params: ["runId": AnyCodable(runID)]
        )
        activeRunID = nil
    }

    private func setActiveRunID(_ runID: String?) async {
        activeRunID = runID
    }

    private func removeStream(id: UUID) async {
        eventContinuations.removeValue(forKey: id)
    }

    private func sendRequest(
        method: String,
        params: [String: AnyCodable]?
    ) async throws -> MoltisProtocol.Response {
        guard let webSocket else { throw MoltisGatewayError.notConnected }
        let id = nextID()
        let request = MoltisProtocol.Request(id: id, method: method, params: params)
        let data = try JSONEncoder().encode(request)
        guard let text = String(data: data, encoding: .utf8) else {
            throw MoltisGatewayError.rpcFailed("Could not encode request.")
        }
        return try await withCheckedThrowingContinuation { continuation in
            pending[id] = continuation
            webSocket.send(.string(text)) { error in
                if let error {
                    Task { await self.failRequest(id: id, error: error) }
                }
            }
        }
    }

    private func nextID() -> String {
        defer { nextRequestID += 1 }
        return String(nextRequestID)
    }

    private func failRequest(id: String, error: Error) {
        pending.removeValue(forKey: id)?.resume(throwing: error)
    }

    private func startReceiveLoop() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    let message = try await self.receiveMessage()
                    await self.handle(message: message)
                } catch is CancellationError {
                    break
                } catch {
                    gatewayLogger.error("WebSocket receive failed: \(error.localizedDescription)")
                    await self.broadcastNotice("**Error:** \(error.localizedDescription)")
                    break
                }
            }
        }
    }

    private func receiveMessage() async throws -> URLSessionWebSocketTask.Message {
        guard let webSocket else { throw MoltisGatewayError.notConnected }
        return try await webSocket.receive()
    }

    private func handle(message: URLSessionWebSocketTask.Message) {
        let text: String
        switch message {
        case let .string(value):
            text = value
        case let .data(data):
            guard let value = String(data: data, encoding: .utf8) else { return }
            text = value
        @unknown default:
            return
        }
        guard let data = text.data(using: .utf8) else { return }

        if let response = try? JSONDecoder().decode(MoltisProtocol.Response.self, from: data),
           response.type == "res",
           let id = response.id
        {
            if let continuation = pending.removeValue(forKey: id) {
                continuation.resume(returning: response)
            }
            return
        }

        guard let event = try? JSONDecoder().decode(MoltisProtocol.Event.self, from: data),
              event.type == "event",
              event.event == "chat",
              let payload = event.payload
        else { return }

        dispatchChatEvent(payload)
    }

    private func dispatchChatEvent(_ payload: MoltisProtocol.ChatPayload) {
        let state = payload.state ?? ""
        switch state {
        case "delta":
            if let text = payload.text, !text.isEmpty {
                broadcast(MoltisChatStreamEvent(kind: .textDelta(text)))
            }
        case "thinking":
            broadcast(MoltisChatStreamEvent(kind: .thinking))
        case "tool_call_start":
            let name = payload.tool ?? "tool"
            broadcast(MoltisChatStreamEvent(kind: .toolStart(name: name)))
        case "tool_call_end":
            let name = payload.tool ?? "tool"
            broadcast(MoltisChatStreamEvent(kind: .toolEnd(name: name, rejected: payload.rejected == true)))
        case "final":
            broadcast(MoltisChatStreamEvent(kind: .final))
            activeRunID = nil
            finishStreams()
        default:
            break
        }
    }

    private func broadcast(_ event: MoltisChatStreamEvent) {
        for continuation in eventContinuations.values {
            continuation.yield(event)
        }
    }

    private func broadcastNotice(_ text: String) {
        broadcast(MoltisChatStreamEvent(kind: .notice(text)))
    }

    private func finishStreams() {
        for continuation in eventContinuations.values {
            continuation.finish()
        }
        eventContinuations.removeAll()
    }
}

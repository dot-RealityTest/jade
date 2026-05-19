import SwiftUI

struct AIAssistantSettingsView: View {
    @State private var baseURL = NaturalCommandSettings.shared.ollamaBaseURL
    @State private var model = NaturalCommandSettings.shared.ollamaModel
    @State private var availableModels: [String] = []
    @State private var isFetching = false
    @State private var fetchError: String?
    @State private var showError = false

    var body: some View {
        SettingsContainer {
            SettingsSection("Ollama Backend") {
                SettingsRow("Base URL") {
                    TextField("http://localhost:11434", text: $baseURL)
                        .font(.system(size: SettingsMetrics.labelFontSize))
                        .frame(width: SettingsMetrics.controlWidth, alignment: .trailing)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { save() }
                }

                if availableModels.isEmpty {
                    SettingsRow("Model") {
                        HStack(spacing: 8) {
                            TextField("llama3.2", text: $model)
                                .font(.system(size: SettingsMetrics.labelFontSize))
                                .frame(width: 160, alignment: .trailing)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { save() }

                            Button {
                                fetchModels()
                            } label: {
                                HStack(spacing: 4) {
                                    if isFetching {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    Text("Fetch")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .buttonStyle(.borderless)
                            .disabled(isFetching)
                        }
                        .frame(width: SettingsMetrics.controlWidth, alignment: .trailing)
                    }
                } else {
                    SettingsRow("Model") {
                        Picker("", selection: $model) {
                            ForEach(availableModels, id: \.self) { m in
                                Text(m).tag(m)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: SettingsMetrics.controlWidth, alignment: .trailing)
                        .onChange(of: model) { _, _ in save() }
                    }
                }

                if !availableModels.isEmpty {
                    SettingsRow("") {
                        Button {
                            availableModels = []
                        } label: {
                            Text("Custom model")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                        .frame(width: SettingsMetrics.controlWidth, alignment: .trailing)
                    }
                }
            }

            if let error = fetchError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, SettingsMetrics.horizontalPadding)
                    .padding(.top, 4)
            }
        }
        .alert("Connection Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(fetchError ?? "Could not reach Ollama.")
        }
    }

    private func save() {
        NaturalCommandSettings.shared.ollamaBaseURL = baseURL
        NaturalCommandSettings.shared.ollamaModel = model
    }

    private func fetchModels() {
        isFetching = true
        fetchError = nil
        Task {
            defer { isFetching = false }
            guard let url = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                fetchError = "Invalid URL"
                showError = true
                return
            }
            var request = URLRequest(url: url.appending(path: "api/tags"))
            request.timeoutInterval = 3
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else {
                    fetchError = "Ollama returned an error"
                    showError = true
                    return
                }
                let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
                let names = decoded.models.map(\.name).sorted()
                await MainActor.run {
                    availableModels = names
                    if !names.contains(model), let first = names.first {
                        model = first
                        save()
                    }
                }
            } catch {
                fetchError = error.localizedDescription
                showError = true
            }
        }
    }
}

private struct OllamaTagsResponse: Codable {
    struct Model: Codable {
        let name: String
    }

    let models: [Model]
}

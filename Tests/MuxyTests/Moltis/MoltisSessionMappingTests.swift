import Foundation
import Testing
@testable import Muxy

@Test func moltisSessionKeyIsStablePerProject() {
    let projectID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let key = MoltisSessionMapping.sessionKey(for: projectID)
    #expect(key == "jade-11111111-1111-1111-1111-111111111111")
}

@Test func moltisProtocolConnectParamsIncludeVersionRange() throws {
    let params = MoltisProtocol.connectParams()
    let protocolValue = params["protocol"]?.value as? [String: Any]
    #expect(protocolValue?["min"] as? Int == 3)
    #expect(protocolValue?["max"] as? Int == 4)
}

@Test func moltisProtocolResponseParsesRunID() throws {
    let json = """
    {"type":"res","id":"1","ok":true,"payload":{"ok":true,"runId":"abc-123"}}
    """
    let data = Data(json.utf8)
    let response = try JSONDecoder().decode(MoltisProtocol.Response.self, from: data)
    #expect(response.runID == "abc-123")
}

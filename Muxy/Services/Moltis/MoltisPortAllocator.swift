import Foundation
import Network

enum MoltisPortAllocator {
    static func availablePort(preferred: Int) -> Int {
        if isPortAvailable(preferred) {
            return preferred
        }
        for offset in 1 ..< 200 {
            let candidate = preferred + offset
            if candidate > 65535 { break }
            if isPortAvailable(candidate) {
                return candidate
            }
        }
        return preferred
    }

    private static func isPortAvailable(_ port: Int) -> Bool {
        guard port > 0, port <= 65535 else { return false }
        let parameters = NWParameters.tcp
        guard let endpointPort = NWEndpoint.Port(rawValue: UInt16(port)),
              let listener = try? NWListener(using: parameters, on: endpointPort)
        else {
            return false
        }
        listener.start(queue: .global())
        listener.cancel()
        return true
    }
}

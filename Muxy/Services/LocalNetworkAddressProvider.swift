import Darwin
import Foundation

struct LocalNetworkInterfaceAddress: Equatable {
    let name: String
    let address: String
    let isIPv4: Bool
    let isLoopback: Bool
}

enum LocalNetworkAddressProvider {
    static func connectionURL(port: UInt16, address: String? = localIPv4Address()) -> String? {
        guard let address else { return nil }
        return "http://\(address):\(port)"
    }

    static func localIPv4Address() -> String? {
        preferredIPv4Address(from: interfaceAddresses())
    }

    static func preferredIPv4Address(from interfaces: [LocalNetworkInterfaceAddress]) -> String? {
        let candidates = interfaces.filter { $0.isIPv4 && !$0.isLoopback }
        if let preferred = candidates.first(where: { $0.name == "en0" || $0.name == "en1" }) {
            return preferred.address
        }
        return candidates.first?.address
    }

    private static func interfaceAddresses() -> [LocalNetworkInterfaceAddress] {
        var addresses: [LocalNetworkInterfaceAddress] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        defer { freeifaddrs(ifaddr) }

        var pointer = ifaddr
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            guard let socketAddress = current.pointee.ifa_addr else { continue }
            guard Int32(socketAddress.pointee.sa_family) == AF_INET else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                socketAddress,
                socklen_t(socketAddress.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard result == 0 else { continue }

            let flags = Int32(current.pointee.ifa_flags)
            let addressBytes = hostname.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
            guard let address = String(bytes: addressBytes, encoding: .utf8) else { continue }
            addresses.append(LocalNetworkInterfaceAddress(
                name: String(cString: current.pointee.ifa_name),
                address: address,
                isIPv4: true,
                isLoopback: flags & IFF_LOOPBACK != 0
            ))
        }
        return addresses
    }
}

import Foundation
import Testing

@testable import Muxy

@Suite("LocalNetworkAddressProvider")
struct LocalNetworkAddressProviderTests {
    @Test("connectionURL formats address and port")
    func connectionURLFormatsAddressAndPort() {
        #expect(LocalNetworkAddressProvider.connectionURL(port: 23779, address: "192.168.1.10") == "http://192.168.1.10:23779")
    }

    @Test("connectionURL returns nil without address")
    func connectionURLReturnsNilWithoutAddress() {
        #expect(LocalNetworkAddressProvider.connectionURL(port: 23779, address: nil) == nil)
    }

    @Test("preferredIPv4Address prefers en0 then non-loopback IPv4")
    func preferredIPv4AddressPrefersEn0ThenNonLoopbackIPv4() {
        let interfaces = [
            LocalNetworkInterfaceAddress(name: "lo0", address: "127.0.0.1", isIPv4: true, isLoopback: true),
            LocalNetworkInterfaceAddress(name: "utun5", address: "100.64.0.2", isIPv4: true, isLoopback: false),
            LocalNetworkInterfaceAddress(name: "en0", address: "192.168.1.10", isIPv4: true, isLoopback: false),
        ]

        #expect(LocalNetworkAddressProvider.preferredIPv4Address(from: interfaces) == "192.168.1.10")
    }

    @Test("preferredIPv4Address falls back to first non-loopback IPv4")
    func preferredIPv4AddressFallsBackToFirstNonLoopbackIPv4() {
        let interfaces = [
            LocalNetworkInterfaceAddress(name: "lo0", address: "127.0.0.1", isIPv4: true, isLoopback: true),
            LocalNetworkInterfaceAddress(name: "utun5", address: "100.64.0.2", isIPv4: true, isLoopback: false),
        ]

        #expect(LocalNetworkAddressProvider.preferredIPv4Address(from: interfaces) == "100.64.0.2")
    }
}

import Foundation
import Testing
@testable import SBNetworking

@Suite("HTTPClientLoggingPolicy")
struct HTTPClientLoggingPolicyTests {

    @Test("booleans and numbers")
    func booleansAndNumbers() {
        #expect(HTTPClientLoggingPolicy.isEnabled(true))
        #expect(!HTTPClientLoggingPolicy.isEnabled(false))
        #expect(HTTPClientLoggingPolicy.isEnabled(NSNumber(value: 1)))
        #expect(!HTTPClientLoggingPolicy.isEnabled(NSNumber(value: 0)))
    }

    /// What a host app's plist actually holds when the value comes from a
    /// build setting: `<string>YES</string>`.
    @Test("strings from substituted build settings")
    func strings() {
        for on in ["YES", "yes", "Yes", "TRUE", "true", "1", " YES\n"] {
            #expect(HTTPClientLoggingPolicy.isEnabled(on), "\(on)")
        }
        for off in ["NO", "no", "false", "0", "", "$(SBNetworkingHTTPLogEnabled)", "maybe"] {
            #expect(!HTTPClientLoggingPolicy.isEnabled(off), "\(off)")
        }
    }

    @Test("absent or unexpected types are off")
    func absent() {
        #expect(!HTTPClientLoggingPolicy.isEnabled(nil))
        #expect(!HTTPClientLoggingPolicy.isEnabled(["YES"]))
    }
}

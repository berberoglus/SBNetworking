//
//  HTTPClientLoggingPolicy.swift
//  SBNetworking
//
//  Logging is controlled at runtime via the host app's Info.plist key
//  "SBNetworkingHTTPLogEnabled" (Bool). This avoids relying on SwiftPM
//  debug vs release mapping for custom Xcode configurations (e.g. Local).
//

import Foundation

enum HTTPClientLoggingPolicy {

    /// Reads `SBNetworkingHTTPLogEnabled` from the main bundle Info.plist.
    /// Defaults to `false` when the key is absent (e.g. tests, extensions without plist).
    static var isHttpLoggingEnabled: Bool {
        isEnabled(Bundle.main.object(forInfoDictionaryKey: "SBNetworkingHTTPLogEnabled"))
    }

    /// The toggle's value as the host app's Info.plist holds it. Apps set it
    /// per configuration through a build setting
    /// (`SBNetworkingHTTPLogEnabled = $(SBNetworkingHTTPLogEnabled)`), and a
    /// substituted build setting always lands in the plist as a *string*
    /// ("YES"), never a `<true/>` — so strings count too: YES/TRUE/1, any case.
    /// Anything else, or no value, is off.
    static func isEnabled(_ value: Any?) -> Bool {
        switch value {
        case let bool as Bool:
            return bool
        case let number as NSNumber:
            return number.boolValue
        case let string as String:
            return ["yes", "true", "1"].contains(string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        default:
            return false
        }
    }
}

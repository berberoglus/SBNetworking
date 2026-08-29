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
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SBNetworkingHTTPLogEnabled") else {
            return false
        }
        if let b = value as? Bool { return b }
        if let n = value as? NSNumber { return n.boolValue }
        return false
    }
}

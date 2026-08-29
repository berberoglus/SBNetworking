//
//  HTTPClientLogRedactor.swift
//  SBNetworking
//
//  Debug logging must stay useful without ever printing credentials: values
//  of credential-bearing headers are replaced with a placeholder, and
//  request/response bodies are suppressed entirely for auth-style endpoints
//  (their bodies carry emails, one-time codes, and session tokens).
//

import Foundation

enum HTTPClientLogRedactor {

    static let placeholder = "[REDACTED]"

    /// Header names (lowercased) whose values never reach the log.
    static let sensitiveHeaderNames: Set<String> = [
        "authorization",
        "proxy-authorization",
        "apikey",
        "s-api-key",
        "x-api-key",
        "cookie",
        "set-cookie"
    ]

    static func redactedHeaders(_ headers: [String: String]?) -> [String: String] {
        guard let headers else { return [:] }
        return headers.reduce(into: [:]) { result, pair in
            let isSensitive = sensitiveHeaderNames.contains(pair.key.lowercased())
            result[pair.key] = isSensitive ? placeholder : pair.value
        }
    }

    /// Bodies are suppressed for endpoints whose payloads are credentials by
    /// nature. Matches any path component that equals "token"/"login"/"signup"
    /// or starts with "auth" (auth, auth-otp, auth-refresh, ...). A missing
    /// URL is treated as sensitive — when in doubt, do not log the body.
    static func isBodySensitive(for url: URL?) -> Bool {
        guard let url else { return true }
        return url.pathComponents.contains { component in
            let normalized = component.lowercased()
            return normalized.hasPrefix("auth")
                || normalized == "token"
                || normalized == "login"
                || normalized == "signup"
        }
    }
}

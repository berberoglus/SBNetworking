//
//  AuthTokenProvider.swift
//  SBNetworking
//

import Foundation

/// Protocol for providing auth tokens and optional refresh logic.
///
/// When provided to `HttpClientProtocol.authTokenProvider`, the client will:
/// - Add `apikey` header from `apiKey` (if present)
/// - Add `Authorization: Bearer {accessToken}` (if present)
/// - On 401: call `refresh()` then retry the request once
///
/// Override `refresh()` to enable 401 retry. Default implementation throws `HTTPClientError.unauthorized`.
/// Use `apikey` header name (not S-Api-Key) for Supabase compatibility.
public protocol AuthTokenProvider: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var apiKey: String? { get }
    func updateTokens(accessToken: String, refreshToken: String)
    func refresh() async throws
}

public extension AuthTokenProvider {
    /// Default: no refresh support. Override to enable 401 retry.
    func refresh() async throws {
        throw HTTPClientError.unauthorized
    }
}

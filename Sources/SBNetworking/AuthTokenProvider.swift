//
//  AuthTokenProvider.swift
//  SBNetworking
//

import Foundation

/// Protocol for providing auth tokens and optional refresh logic.
///
/// When provided to `HttpClientProtocol.authTokenProvider`, the client will:
/// - Add one header per `apiKeyHeaderNames` entry from `apiKey` (if present)
/// - Add `Authorization: Bearer {accessToken}` (if present)
/// - On 401: call `refresh()` then retry the request once
///
/// Override `refresh()` to enable 401 retry. Default implementation throws `HTTPClientError.unauthorized`.
/// The API-key header name is a backend-specific decision, so it belongs to the
/// conforming app: override `apiKeyHeaderNames` to match your gateway (the default
/// `["apikey"]` preserves the pre-1.0.7 behavior).
public protocol AuthTokenProvider: AnyObject, Sendable {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var apiKey: String? { get }
    /// Header name(s) the `apiKey` value is sent under. Every listed name gets the
    /// same key value. Gateways differ (`apikey`, `s-api-key`, `x-api-key`, ...) and
    /// some drop specific names when an `Authorization` header is present — apps can
    /// list several names to satisfy all their environments.
    var apiKeyHeaderNames: [String] { get }
    func updateTokens(accessToken: String, refreshToken: String)
    func refresh() async throws
}

public extension AuthTokenProvider {
    /// Default: no refresh support. Override to enable 401 retry.
    func refresh() async throws {
        throw HTTPClientError.unauthorized
    }

    /// Default: the single `apikey` header (pre-1.0.7 behavior).
    var apiKeyHeaderNames: [String] { ["apikey"] }
}

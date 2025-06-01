//
//  HTTPClientEnvironment.swift
//  SBNetworking
//
//  Created by Samet Berberoglu on 2025-06-01.
//

import Foundation

/// Configuration for HTTP client network requests.
///
/// `HTTPClientEnvironment` encapsulates the settings required for configuring an HTTP client's
/// network environment, including the base URL and scheme. This struct provides a simple way
/// to define different API environments (development, production, staging, etc.).
///
/// ## Example Usage:
/// ```swift
/// // Create a production environment
/// let prodEnv = HTTPClientEnvironment(baseURL: "api.example.com")
///
/// // Create a development environment with custom scheme
/// let devEnv = HTTPClientEnvironment(scheme: "http", baseURL: "dev-api.example.com")
///
/// // Use the environment with an HTTP client
/// let client = HTTPClient(client: HttpClientProtocol(environment: prodEnv))
/// ```

public struct HTTPClientEnvironment {
    let scheme: String
    let baseURL: String
    public init(
        scheme: String = "https",
        baseURL: String
    ) {
        self.scheme = scheme
        self.baseURL = baseURL
    }
}

//
//  HTTPClientError.swift
//  SBNetworking
//
//  Created by Samet Berberoglu on 2025-06-01.
//

import Foundation

/// Enum representing HTTP and network errors.
///
/// This enum provides a comprehensive set of error cases that can occur during HTTP networking
/// operations. It includes both client-side errors (like URL formatting issues) and server-side
/// errors (like 4xx and 5xx HTTP status codes).
///
/// ## Example Usage:
/// ```swift
/// do {
///     let response = try await client.submitRequest(endpoint: endpoint)
///     // Handle successful response
/// } catch let error as HTTPClientError {
///     switch error {
///     case .unauthorized:
///         // Handle 401 Unauthorized
///     case .networkConnectionLost:
///         // Handle network connectivity issues
///     default:
///         // Handle other errors
///     }
/// }
/// ```
///

public enum HTTPClientError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case unauthorized
    case clientError(statusCode: Int)
    case serverError(statusCode: Int, data: Data)
    case unexpectedStatusCode
    case notFound
    case notConnectedToInternet
    case networkConnectionLost
    case notImplemented
}

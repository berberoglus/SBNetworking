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

extension HTTPClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL format or construction"
        case .invalidResponse:
            return "Invalid or malformed server response"
        case .decodingFailed:
            return "Failed to decode the response data"
        case .unauthorized:
            return "Authentication required (401)"
        case .clientError(let statusCode):
            return "Client error (HTTP \(statusCode))"
        case .serverError(let statusCode, let data):
            let dataStr = String(describing: String(data: data, encoding: .utf8))
            return "Server error (HTTP \(statusCode))\nResponse data: \(dataStr)"
        case .unexpectedStatusCode:
            return "Received an unexpected HTTP status code"
        case .notFound:
            return "Resource not found (404)"
        case .notConnectedToInternet:
            return "No internet connection available"
        case .networkConnectionLost:
            return "Network connection was lost during the request"
        case .notImplemented:
            return "The requested operation is not implemented"
        }
    }
}

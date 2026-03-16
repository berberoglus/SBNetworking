//
//  Enpoint.swift
//  SBNetworking
//
//  Created by Samet Berberoglu on 2025-06-01.
//

import Foundation

/// Protocol used to define API endpoints.
///
/// The `Endpoint` protocol is the core abstraction for defining network requests in the SBNetworking library.
/// Each endpoint represents a specific API endpoint with its path, HTTP method, parameters, etc.
///
/// ## Example Usage:
/// ```swift
/// struct SearchEndpoint: Endpoint {
///     typealias ResponseType = SearchResponse
///     
///     let searchTerm: String
///     
///     var path: String { "/search" }
///     var method: HTTPMethod { .get }
///     var queryParameters: [String: String]? {
///         ["term": searchTerm, "entity": "song"]
///     }
/// }
/// ```

public protocol Endpoint {
    associatedtype ResponseType: ResponseProtocol
    var path: String { get }
    var method: HTTPMethod { get }
    var headerFields: [String: String]? { get }
    var payload: Encodable? { get }
    var queryParameters: [String: String]? { get }
    var timeoutInterval: TimeInterval { get }
}

public extension Endpoint {
    var headerFields: [String: String]? { nil }
    var payload: Encodable? { nil }
    var queryParameters: [String: String]? { nil }
    var timeoutInterval: TimeInterval { 20.0 }
}

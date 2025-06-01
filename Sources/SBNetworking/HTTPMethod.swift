//
//  HTTPMethod.swift
//  SBNetworking
//
//  Created by Samet Berberoglu on 2025-06-01.
//

import Foundation

/// Enum representing HTTP request methods.
///
/// This enum defines the standard HTTP methods used for RESTful API requests.
/// Each case corresponds to a standard HTTP method.
///
/// ## Example Usage:
/// ```swift
/// let request = URLRequest(url: url)
/// request.httpMethod = HTTPMethod.post.rawValue
/// ```

public enum HTTPMethod: String {
    case `get` = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

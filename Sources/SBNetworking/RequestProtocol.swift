//
//  RequestProtocol.swift
//  SBNetworking
//
//  Created by Havva Fırtına on 2026-03-16.
//

import Foundation

/// Describes a type that can be transformed into a concrete `Endpoint`.
///
/// Conforming types usually represent feature-level request models.
/// This allows higher layers to work with typed request objects and defer the
/// transport-level endpoint construction to the request itself.
///
/// - Important: The returned endpoint must fully describe the request that will be sent,
/// including its path, HTTP method, payload, headers, and query parameters where needed.
public protocol EndpointConvertible {
    associatedtype EndpointType: Endpoint

    /// Converts the current value into a concrete endpoint definition.
    func toEndpoint() -> EndpointType
}

/// A marker protocol for request models that can be transformed into a concrete `Endpoint`.
///
/// Conforming types represent feature-level input objects.
/// They should stay focused on request data and map themselves to a transport-level endpoint
/// via `toEndpoint()`.
///
/// This protocol is intended for use in the networking SPM so feature modules can build
/// typed requests without directly depending on low-level endpoint construction details.
public protocol RequestProtocol: EndpointConvertible, Encodable, Sendable { }

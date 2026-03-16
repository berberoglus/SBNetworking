//
//  ResponseProtocol.swift
//  SBNetworking
//
//  Created by Havva Fırtına on 2026-03-16.
//

import Foundation

/// Describes a transport-level response object that can be converted into a higher-level model.
///
/// Conforming types are typically DTOs decoded directly from the network response body.
/// They are responsible for transforming themselves into a domain or feature model
/// through `toModel()`.
///
/// This protocol is intended for use in the networking SPM so feature modules can keep
/// transport models and domain models clearly separated while preserving strong typing.
public protocol ModelConvertible {
    associatedtype ModelType

    /// Converts the current transport object into its higher-level model representation.
    func toModel() -> ModelType
}

/// A typed response contract for decoded network payloads.
///
/// Conforming types must:
/// - be decodable from the raw response body
/// - be safe to pass across concurrency boundaries
/// - provide a conversion into a higher-level model via `toModel()`
///
/// This protocol is intended for transport-layer DTOs, not for domain models directly.
public protocol ResponseProtocol: Decodable, ModelConvertible, Sendable { }

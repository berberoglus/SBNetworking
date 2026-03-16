//
//  MockUrlProtocol.swift
//  SBNetworking
//
//  Created by Samet Berberoğlu on 2025-06-01.
//

import Foundation
import Testing

/// Custom URLProtocol subclass for mocking network responses in tests.
///
/// `MockUrlProtocol` intercepts URLSession requests and provides mock responses
/// without making actual network calls. This allows for consistent, deterministic
/// testing of networking code.
///
/// ## Example Usage:
/// ```swift
/// // Setup
/// let config = URLSessionConfiguration.ephemeral
/// config.protocolClasses = [MockUrlProtocol.self]
/// let session = URLSession(configuration: config)
///
/// // Register mock data
/// let testURL = URL(string: "https://example.com/api")!
/// let testData = "{\"key\": \"value\"}".data(using: .utf8)!
/// MockUrlProtocol.testSamples[testURL] = testData
///
/// // Use the session in your tests
/// let (data, _) = try await session.data(from: testURL)
/// // data will be the test data you registered
/// ```
///

final class MockUrlProtocol: URLProtocol {
    /// Storage for mock responses, mapping URLs to data.
    /// This dictionary is used to provide predetermined responses for specific URLs.
    ///
    /// - Warning: This property is marked as `nonisolated(unsafe)` for backward compatibility.
    ///   For production code, consider using a thread-safe alternative.
    nonisolated(unsafe) static var testSamples = [URL?: Data]()

    /// Optional queue of (statusCode, data) per URL. When set, each request consumes the next in queue.
    /// Used for testing 401 → retry → 200 flows. Falls back to testSamples (200) when queue is empty.
    nonisolated(unsafe) static var testResponseQueue = [URL?: [(statusCode: Int, data: Data)]]()

    /// Same as testResponseQueue but keyed by path for flexible matching when URL identity differs.
    nonisolated(unsafe) static var testResponseQueueByPath = [String: [(statusCode: Int, data: Data)]]()

    /// Same as testSamples but keyed by path.
    nonisolated(unsafe) static var testSamplesByPath = [String: Data]()

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func stopLoading() { }

    /// Starts loading the request.
    ///
    /// This is where the mock response is provided. The method:
    /// 1. Tries to get the URL from the request
    /// 2. Looks up mock data for that URL (or next item in testResponseQueue)
    /// 3. Creates and sends a mock HTTP response with the data
    /// 4. Notifies the client that loading is finished
    override func startLoading() {
        do {
            let url = try #require(request.url, "Request URL is nil")
            let statusCode: Int
            let data: Data
            let pathKey = url.path
            let pathKeyAlt = pathKey.hasPrefix("/") ? String(pathKey.dropFirst()) : "/" + pathKey
            if var queue = Self.testResponseQueue[url], !queue.isEmpty {
                let item = queue.removeFirst()
                Self.testResponseQueue[url] = queue.isEmpty ? nil : queue
                statusCode = item.statusCode
                data = item.data
            } else if var queue = Self.testResponseQueueByPath[pathKey], !queue.isEmpty {
                let item = queue.removeFirst()
                Self.testResponseQueueByPath[pathKey] = queue.isEmpty ? nil : queue
                statusCode = item.statusCode
                data = item.data
            } else if var queue = Self.testResponseQueueByPath[pathKeyAlt], !queue.isEmpty {
                let item = queue.removeFirst()
                Self.testResponseQueueByPath[pathKeyAlt] = queue.isEmpty ? nil : queue
                statusCode = item.statusCode
                data = item.data
            } else if let fallback = Self.testSamples[url] {
                statusCode = 200
                data = fallback
            } else if let fallback = Self.testSamplesByPath[pathKey] ?? Self.testSamplesByPath[pathKeyAlt] {
                statusCode = 200
                data = fallback
            } else {
                throw NSError(
                    domain: "MockUrlProtocol",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No test data found for URL: \(url.absoluteString)"]
                )
            }

            let response = try #require(
                HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )
            )
            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )

            client?.urlProtocol(self, didLoad: data)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
}

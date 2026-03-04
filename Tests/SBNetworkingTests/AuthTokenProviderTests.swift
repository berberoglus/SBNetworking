//
//  AuthTokenProviderTests.swift
//  SBNetworking
//

import Foundation
import Testing
@testable import SBNetworking

@Suite(.serialized)
final class AuthTokenProviderTests {

    // MARK: - Auth headers from provider

    @Test
    func testAuthTokenProviderAddsApikeyAndAuthorizationHeaders() throws {
        let provider = MockAuthTokenProvider(
            accessToken: "access_123",
            refreshToken: "refresh_456",
            apiKey: "anon_key_xyz"
        )
        let config = AuthTestClientConfig(authTokenProvider: provider)
        let endpoint = DummyGetEndpoint()

        let request = try TestHelpers.generateRequest(client: config, endpoint: endpoint)

        #expect(request.allHTTPHeaderFields?["apikey"] == "anon_key_xyz")
        #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer access_123")
    }

    @Test
    func testAuthTokenProviderMergesWithEndpointHeaders() throws {
        let provider = MockAuthTokenProvider(
            accessToken: "token",
            refreshToken: nil,
            apiKey: "key"
        )
        let config = AuthTestClientConfig(authTokenProvider: provider)
        struct CustomHeaderEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "/test" }
            var method: HTTPMethod { .get }
            var headerFields: [String: String]? { ["X-Custom": "value"] }
        }
        let endpoint = CustomHeaderEndpoint()

        let request = try TestHelpers.generateRequest(client: config, endpoint: endpoint)

        #expect(request.allHTTPHeaderFields?["apikey"] == "key")
        #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer token")
        #expect(request.allHTTPHeaderFields?["X-Custom"] == "value")
    }

    @Test
    func testNilAuthTokenProviderDoesNotAddAuthHeaders() throws {
        let config = AuthTestClientConfig(authTokenProvider: nil)
        let endpoint = DummyGetEndpoint()

        let request = try TestHelpers.generateRequest(client: config, endpoint: endpoint)

        #expect(request.allHTTPHeaderFields?["apikey"] == nil)
        #expect(request.allHTTPHeaderFields?["Authorization"] == nil)
    }

    // MARK: - 401 refresh and retry

    @Test
    func test401WithRefreshRetriesAndSucceeds() async throws {
        let provider = MockAuthTokenProvider(
            accessToken: "old_token",
            refreshToken: "refresh_xyz",
            apiKey: "key",
            supportsRefresh: true
        )
        let config = AuthTestClientConfig(authTokenProvider: provider)
        let endpoint = DummyRetryEndpoint()
        let successData = "{\"resultCount\": 1}".data(using: .utf8)!
        MockUrlProtocol.testResponseQueueByPath = [
            "/dummy-retry": [(401, "{\"error\":\"unauthorized\"}".data(using: .utf8)!), (200, successData)],
            "dummy-retry": [(401, "{\"error\":\"unauthorized\"}".data(using: .utf8)!), (200, successData)]
        ]
        MockUrlProtocol.testSamplesByPath = ["/dummy-retry": successData, "dummy-retry": successData]
        defer {
            MockUrlProtocol.testResponseQueueByPath = [:]
            MockUrlProtocol.testSamplesByPath = [:]
        }

        let client = HTTPClient(client: config)
        let response = try await client.submitRequest(endpoint: endpoint)

        #expect(response != nil)
        #expect(response?.resultCount == 1)
        #expect(provider.updateTokensCallCount == 1)
    }

    @Test
    func test401WithoutProviderThrowsUnauthorized() async throws {
        let config = AuthTestClientConfig(authTokenProvider: nil)
        let endpoint = Dummy401Endpoint()

        MockUrlProtocol.testResponseQueueByPath = ["/dummy-401": [(401, Data())], "dummy-401": [(401, Data())]]
        defer { MockUrlProtocol.testResponseQueueByPath = [:] }

        let client = HTTPClient(client: config)
        do {
            _ = try await client.submitRequest(endpoint: endpoint)
            Issue.record("Expected to throw HTTPClientError.unauthorized")
        } catch let error as HTTPClientError {
            #expect(error == .unauthorized)
        }
    }

    @Test
    func test401WithRefreshThatThrowsPropagatesError() async throws {
        struct RefreshError: Error {}
        let provider = MockAuthTokenProvider(
            accessToken: "token",
            refreshToken: "refresh",
            apiKey: "key",
            refreshThrows: RefreshError()
        )
        let config = AuthTestClientConfig(authTokenProvider: provider)
        let endpoint = Dummy401Endpoint()

        MockUrlProtocol.testResponseQueueByPath = ["/dummy-401": [(401, Data())], "dummy-401": [(401, Data())]]
        defer { MockUrlProtocol.testResponseQueueByPath = [:] }

        let client = HTTPClient(client: config)
        do {
            _ = try await client.submitRequest(endpoint: endpoint)
            Issue.record("Expected to throw RefreshError")
        } catch is RefreshError {
            // Expected
        }
    }
}

// MARK: - Test helpers

private struct DummyGetEndpoint: Endpoint {
    typealias ResponseType = DummyResponse
    var path: String { "/dummy" }
    var method: HTTPMethod { .get }
}

private struct DummyRetryEndpoint: Endpoint {
    typealias ResponseType = DummyResponse
    var path: String { "/dummy-retry" }
    var method: HTTPMethod { .get }
}

private struct Dummy401Endpoint: Endpoint {
    typealias ResponseType = DummyResponse
    var path: String { "/dummy-401" }
    var method: HTTPMethod { .get }
}

private struct AuthTestClientConfig: HttpClientProtocol {
    let environment: HTTPClientEnvironment
    let authTokenProvider: AuthTokenProvider?
    var urlSession: URLSession { TestHelpers.urlSession }

    init(authTokenProvider: AuthTokenProvider?) {
        self.environment = HTTPClientEnvironment(baseURL: "api.test.com")
        self.authTokenProvider = authTokenProvider
    }
}

private final class MockAuthTokenProvider: AuthTokenProvider {
    var accessToken: String?
    var refreshToken: String?
    var apiKey: String?
    var updateTokensCallCount = 0
    private let supportsRefresh: Bool
    private let refreshError: Error?

    init(accessToken: String?, refreshToken: String?, apiKey: String?, supportsRefresh: Bool = false, refreshThrows: Error? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.apiKey = apiKey
        self.supportsRefresh = supportsRefresh
        self.refreshError = refreshThrows
    }

    func updateTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        updateTokensCallCount += 1
    }

    func refresh() async throws {
        if let refreshError {
            throw refreshError
        }
        guard supportsRefresh else {
            throw HTTPClientError.unauthorized
        }
        updateTokens(accessToken: "new_token", refreshToken: "new_refresh")
    }
}

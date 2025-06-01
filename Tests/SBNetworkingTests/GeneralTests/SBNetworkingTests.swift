//
//  SBNetworkingTests.swift
//  SBNetworking
//
//  Created by Samet Berberoğlu on 2025-06-01.
//

import Foundation
import Testing
@testable import SBNetworking

final class SBNetworkingTests {

    @Test
    func testCreateDefaultRequest() throws {
        let request = try TestHelpers.generateRequest(
            client: self,
            endpoint: ITunesSearchEndpoint()
        )

        let queryParams = try TestHelpers.queryParameters(from: request.url)
        #expect(request.url?.host == "itunes.apple.com")
        #expect(request.httpMethod == HTTPMethod.get.rawValue)
        #expect(queryParams == ITunesSearchEndpoint.queryParams)
    }

    @Test
    func testEndpointSubmitRequestSuccessfullyDecodesResponse() async throws {
        let referenceData = try TestHelpers.generateDataFrom(fileName: "ITunesSearch")
        let referenceResponse = try TestHelpers.decoded(dataType: ITunesSearchResponseModel.self, from: referenceData)
        let endpoint = ITunesSearchEndpoint()

        let request = try TestHelpers.generateRequest(
            client: self,
            endpoint: endpoint
        )

        MockUrlProtocol.testSamples = [request.url: referenceData]
        let client = HTTPClient(client: self)
        let response = try await client.submitRequest(endpoint: endpoint)

        #expect(response != nil, "Response should not be nil")
        #expect(response?.resultCount == referenceResponse.resultCount, "Result count should match")
        #expect(response?.results.count == referenceResponse.results.count, "Number of results should match")
        #expect(referenceResponse == response, "Response should match reference data")
    }

    @Test
    func testInvalidURLThrowsError() throws {
        struct InvalidEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "invalid/" }
            var method: HTTPMethod { .get }
        }
        let endpoint = InvalidEndpoint()
        let client = HTTPClient(client: self)
        #expect(throws: HTTPClientError.invalidURL) {
            try client.createDefaultRequest(for: endpoint)
        }
    }

    @Test
    func testDummyPayloadEncoding() throws {
        struct DummyDummyPayloadEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "/test" }
            var method: HTTPMethod { .post }
            var payload: Encodable? { DummyPayload(name: "John", age: 30) }
        }

        let endpoint = DummyDummyPayloadEndpoint()
        let client = HTTPClient(client: self)
        let request = try client.createDefaultRequest(for: endpoint)
        #expect(request.httpBody != nil)
        let requestBody = try #require(request.httpBody, "HTTP body should not be nil")
        let decoded = try JSONDecoder().decode(DummyPayload.self, from: requestBody)
        #expect(decoded == DummyPayload(name: "John", age: 30))
    }

    @Test
    func testHeaderFields() throws {
        struct HeaderEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "/test" }
            var method: HTTPMethod { .get }
            var headerFields: [String: String]? { ["Authorization": "Bearer token"] }
        }
        let endpoint = HeaderEndpoint()
        let client = HTTPClient(client: self)
        let request = try client.createDefaultRequest(for: endpoint)
        #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer token")
    }

    @Test
    func testQueryParameters() throws {
        struct QueryEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "/test" }
            var method: HTTPMethod { .get }
            var queryParameters: [String: String]? { ["foo": "bar", "baz": "qux"] }
        }
        let endpoint = QueryEndpoint()
        let client = HTTPClient(client: self)
        let request = try client.createDefaultRequest(for: endpoint)
        let urlString = try #require(request.url?.absoluteString, "URL should not be nil")
        #expect(urlString.contains("foo=bar"))
        #expect(urlString.contains("baz=qux"))
    }

    @Test
    func testHTTPMethods() throws {
        struct MethodEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "/test" }
            var method: HTTPMethod
        }
        let methods: [HTTPMethod] = [.get, .post, .put, .patch, .delete]
        for method in methods {
            let endpoint = MethodEndpoint(method: method)
            let client = HTTPClient(client: self)
            let request = try client.createDefaultRequest(for: endpoint)
            #expect(request.httpMethod == method.rawValue)
        }
    }

    @Test
    func testDecodeFailureThrowsError() throws {
        let response = try #require(
            HTTPURLResponse(
                url: URL(string: "https://itunes.apple.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let invalidData = Data([0x00, 0x01, 0x02])
        let client = HTTPClient(client: self)
        #expect(throws: HTTPClientError.decodingFailed) {
            _ = try client.validateResponse(
                response,
                request: URLRequest(url: response.url!),
                data: invalidData,
                responseType: DummyResponse.self
            )
        }
    }

    @Test
    func testEmptyPath() throws {
        struct EmptyPathEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "" }
            var method: HTTPMethod { .get }
        }
        let endpoint = EmptyPathEndpoint()
        let client = HTTPClient(client: self)
        let request = try client.createDefaultRequest(for: endpoint)
        #expect(request.url?.absoluteString == "https://itunes.apple.com")
    }

    @Test
    func testEmptyQueryParameters() throws {
        struct EmptyQueryEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "/test" }
            var method: HTTPMethod { .get }
            var queryParameters: [String: String]? { [:] }
        }
        let endpoint = EmptyQueryEndpoint()
        let client = HTTPClient(client: self)
        let request = try client.createDefaultRequest(for: endpoint)
        let urlString = try #require(request.url?.absoluteString, "URL should not be nil")
        #expect(!urlString.contains("?"))
    }

    @Test
    func testNilPayloadDoesNotSetHTTPBody() throws {
        struct NilPayloadEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "/test" }
            var method: HTTPMethod { .post }
            var payload: Encodable? { nil }
        }
        let endpoint = NilPayloadEndpoint()
        let client = HTTPClient(client: self)
        let request = try client.createDefaultRequest(for: endpoint)
        #expect(request.httpBody == nil)
    }

    @Test
    func testVeryLargePayloadEncoding() throws {
        struct LargePayload: Codable, Equatable {
            let data: [Int]
        }
        struct LargePayloadEndpoint: Endpoint {
            typealias ResponseType = DummyResponse
            var path: String { "/test" }
            var method: HTTPMethod { .post }
            var payload: Encodable? { LargePayload(data: Array(0..<100_000_000)) }
        }
        let endpoint = LargePayloadEndpoint()
        let client = HTTPClient(client: self)
        let request = try client.createDefaultRequest(for: endpoint)
        #expect(request.httpBody != nil)
        let decoded = try JSONDecoder().decode(LargePayload.self, from: request.httpBody!)
        #expect(decoded == LargePayload(data: Array(0..<100_000_000)))
    }

    @Test
    func testUnusualStatusCodes() throws {
        let client = HTTPClient(client: self)
        let url = URL(string: "https://itunes.apple.com")!
        let request = URLRequest(url: url)
        let data = Data()
        let codesAndErrors: [(Int, HTTPClientError)] = [
            (402, .clientError(statusCode: 402)),
            (418, .clientError(statusCode: 418)),
            (500, .serverError(statusCode: 500, data: data)),
            (599, .serverError(statusCode: 599, data: data)),
            (999, .unexpectedStatusCode)
        ]
        for (code, expectedError) in codesAndErrors {
            let response = try #require(
                HTTPURLResponse(
                    url: url,
                    statusCode: code,
                    httpVersion: nil,
                    headerFields: nil
                )
            )

            #expect(throws: expectedError) {
                try client.validateResponse(
                    response,
                    request: request,
                    data: data,
                    responseType: DummyResponse.self
                )
            }
        }
    }
}

// MARK: - HttpClientProtocol

extension SBNetworkingTests: HttpClientProtocol {
    var urlSession: URLSession {
        return TestHelpers.urlSession
    }

    var environment: HTTPClientEnvironment {
        return HTTPClientEnvironment(baseURL: "itunes.apple.com")
    }
}

// MARK: - Endpoint and Response Models

struct ITunesSearchEndpoint: Endpoint {
    typealias ResponseType = ITunesSearchResponseModel
    static let queryParams = ["term": "star wars", "entity": "ebook", "limit": "100"]

    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var queryParameters: [String: String]? { Self.queryParams }
}

struct ITunesSearchResponseModel: Codable, Equatable {
    let resultCount: Int
    let results: [ITunesEntityTestModel]
}

struct ITunesEntityTestModel: Codable, Equatable {
    let artistId: Int
    let trackId: Int
    let artistName: String
    let trackName: String
    let artworkUrl100: URL?
    let releaseDate: String
    let genres: [String]
    let formattedPrice: String?
    let trackViewUrl: URL?
    let description: String?
}

struct DummyResponse: Decodable {
    let resultCount: Int
}

struct DummyPayload: Codable, Equatable {
    let name: String
    let age: Int
}

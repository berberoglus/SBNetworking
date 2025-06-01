//
//  HTTPClient.swift
//  SBNetworking
//
//  Created by Samet Berberoglu on 2025-06-01.
//

import Foundation

/// Protocol defining the interface for HTTP clients.
///
/// This protocol establishes the contract for HTTP client implementations, allowing for
/// dependency injection and testability. It defines the core properties required for
/// making network requests, including the URLSession to use and the environment configuration.
///
/// By conforming to this protocol, different implementations can be created for various
/// scenarios (production, testing, mock) while maintaining a consistent interface.
///
/// ## Example Usage:
/// ```swift
/// struct MockHttpClient: HttpClientProtocol {
///     var urlSession = URLSession(configuration: .ephemeral)
///     var environment = HTTPClientEnvironment(baseURL: "mock-api.example.com")
/// }
///
/// let httpClient = HTTPClient(client: MockHttpClient())
/// ```

public protocol HttpClientProtocol {
    var urlSession: URLSession { get }
    var environment: HTTPClientEnvironment { get }
}

public extension HttpClientProtocol {
    var urlSession: URLSession { URLSession.shared }
}

/// Client used to send network requests.
///
/// `HTTPClient` is the main class for making HTTP requests using the SBNetworking library.
/// It handles the creation of requests, sending them to the server, and processing responses.
///
/// The client uses the Endpoint protocol to define requests and provides type-safe response handling.
///
/// ## Example Usage:
/// ```swift
/// let client = HTTPClient()
/// 
/// // Define your endpoint
/// struct SearchEndpoint: Endpoint {
///     typealias ResponseType = SearchResponse
///     var path: String { "/search" }
///     var method: HTTPMethod { .get }
///     var queryParameters: [String: String]? { ["term": "swift", "entity": "software"] }
/// }
/// 
/// // Make the request
/// do {
///     let response = try await client.submitRequest(endpoint: SearchEndpoint())
///     print("Found \(response.resultCount) results")
/// } catch {
///     print("Error: \(error)")
/// }
///
/// ```

public final class HTTPClient: HttpClientProtocol {

    public let urlSession: URLSession
    public let environment: HTTPClientEnvironment

    public init(client: HttpClientProtocol) {
        self.urlSession = client.urlSession
        self.environment = client.environment
    }

    /// Sends a request to the specified endpoint and returns the decoded response.
    ///
    /// This method handles the entire request-response cycle:
    /// 1. Creates a URLRequest from the endpoint
    /// 2. Sends the request using URLSession
    /// 3. Validates the response
    /// 4. Decodes the response data into the expected type
    ///
    /// - Parameter endpoint: An object conforming to `Endpoint` that defines the request
    /// - Returns: The decoded response object of type specified by the endpoint's `ResponseType`
    /// - Throws: HTTPError if any stage of the request-response cycle fails

    @discardableResult
    public func submitRequest<T: Endpoint>(
        endpoint: T
    ) async throws -> T.ResponseType? {
        let request = try createDefaultRequest(for: endpoint)

        do {
            let (data, response) = try await urlSession.data(for: request)

            return try validateResponse(
                response,
                request: request,
                data: data,
                responseType: T.ResponseType.self
            )
        } catch let error {
            if let urlError = error as? URLError {
                if urlError.code == URLError.Code.notConnectedToInternet {
                    throw HTTPClientError.notConnectedToInternet
                } else if urlError.code == URLError.Code.networkConnectionLost {
                    throw HTTPClientError.networkConnectionLost
                } else {
                    throw error
                }
            } else {
                throw error
            }
        }
    }
    
    func createDefaultRequest<T: Endpoint>(
        for endpoint: T
    ) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = environment.scheme
        components.host = environment.baseURL
        components.path = endpoint.path
        
        if let parameters = endpoint.queryParameters, !parameters.isEmpty {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            print("[HTTPClient] Tried to create an invalid URL: \(components)")
            throw HTTPClientError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headerFields
        request.timeoutInterval = endpoint.timeoutInterval

        if let body = endpoint.payload {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                print("[HTTPClient] Failed to encode payload: \(error)")
                throw HTTPClientError.decodingFailed
            }
        }
        print("[HTTPClient] Request created: \(request)")
        return request
    }

    func validateResponse<T: Decodable>(
        _ response: URLResponse,
        request: URLRequest,
        data: Data,
        responseType: T.Type
    ) throws -> T? {
        var error = HTTPClientError.invalidResponse

        guard let response = response as? HTTPURLResponse else {
            throw error
        }

        switch response.statusCode {
        case 200...299, 304:
            return try decodeResponse(
                request: request,
                response: response,
                data: data,
                responseType: T.self
            )
        case 401:
            error = HTTPClientError.unauthorized
        case 404:
            error = HTTPClientError.notFound
        case 400, 402, 403, 405...499:
            error = HTTPClientError.clientError(statusCode: response.statusCode)
        case 500...599:
            error = HTTPClientError.serverError(statusCode: response.statusCode, data: data)
        default:
            error = HTTPClientError.unexpectedStatusCode
        }
        throw error
    }

    func decodeResponse<T: Decodable>(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        responseType: T.Type
    ) throws -> T? {
        if response.statusCode == 204 {
            return nil
        }

        do {
            let decodedResponse = try JSONDecoder().decode(responseType.self, from: data)
            return decodedResponse
        } catch {
            throw HTTPClientError.decodingFailed
        }
    }
}

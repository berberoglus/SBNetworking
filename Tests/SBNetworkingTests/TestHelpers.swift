//
//  TestHelpers.swift
//  SBNetworking
//
//  Created by Samet Berberoglu on 2025-06-01.
//

import Foundation
import Testing
@testable import SBNetworking

class TestHelpers {

    static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockUrlProtocol.self]
        return URLSession(configuration: configuration)
    }()

    class func generateDataFrom(fileName: String) throws -> Data {
        let path = try #require(
            Bundle.module.path(forResource: fileName, ofType: "json"),
            "\(fileName).json could not be found in the current bundle"
        )
        return try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
    }

    class func queryParameters(from url: URL?) throws -> [String: String] {
        guard let url = url else {
            throw HTTPClientError.invalidURL
        }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
        return queryItems?.reduce(into: [String: String]()) { $0[$1.name] = $1.value } ?? [:]
    }

    class func generateRequest(
        client: HttpClientProtocol,
        endpoint: any Endpoint
    ) throws -> URLRequest {
        return try HTTPClient(client: client).createDefaultRequest(for: endpoint)
    }

    class func decoded<T: Decodable>(dataType: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        let decodedObject = try? decoder.decode(T.self, from: data)
        return try #require(decodedObject, "decodingError")
    }
}

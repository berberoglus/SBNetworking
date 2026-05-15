//
//  HTTPClient+Logging.swift
//  SBNetworking
//
//  Created by Havva Fırtına on 2026-03-29.
//

import Foundation
import os

extension HTTPClient {

    private static let logger: Logger = {
        Logger(subsystem: "SBNetworking", category: "HTTP")
    }()

    func logRequest(_ request: URLRequest) {
        guard HTTPClientLoggingPolicy.isHttpLoggingEnabled else { return }
        let httpMethod = request.httpMethod ?? ""
        let urlString = request.url?.absoluteString ?? ""
        let requestString = ">>>> Request (\(httpMethod)) : \(urlString)"
        let headersString = "Header Fields:\n\(request.allHTTPHeaderFields?.prettyPrintedJsonString ?? "")"

        var bodyString = ""
        if let body = request.httpBody?.prettyPrintedJsonString {
            bodyString = "HTTP Body: \n\(body)"
        }

        Self.logger.info("\(requestString)\n\(headersString)\n\(bodyString)")
    }

    func logResponse(_ response: URLResponse?, requestMethod: String?, data: Data?) {
        guard HTTPClientLoggingPolicy.isHttpLoggingEnabled else { return }
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        let urlString = response?.url?.absoluteString ?? ""
        let responseString = "<<<< Response : (\(requestMethod ?? "")) (\(statusCode)) : \(urlString)"
        let body = data?.prettyPrintedJsonString ?? ""

        Self.logger.info("\(responseString)\n\(body)")
    }

    func logResponse(_ response: URLResponse?, requestMethod: String?, error: Error?) {
        guard HTTPClientLoggingPolicy.isHttpLoggingEnabled else { return }
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        let urlString = response?.url?.absoluteString ?? ""
        let responseString = "<<<< Response : (\(requestMethod ?? "")) (\(statusCode)) : \(urlString)"
        let errorMessage = error?.localizedDescription ?? ""

        Self.logger.info("\(responseString)\n\(errorMessage)\n\(String(describing: error))")
    }

    func logCouldNotDecodeResponse(_ object: Any?) {
        guard HTTPClientLoggingPolicy.isHttpLoggingEnabled else { return }
        guard let object else { return }
        Self.logger.fault("Could Not Decode Response: \(type(of: object))")
    }
}

private extension Data {

    var prettyPrintedJsonString: String {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else { return "" }
        return prettyPrintedString
    }
}

private extension Dictionary where Key == String, Value == String {

    var prettyPrintedJsonString: String {
        guard let jsonData = try? JSONSerialization.data(
            withJSONObject: self,
            options: [.prettyPrinted]
        ) else {
            return ""
        }
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}

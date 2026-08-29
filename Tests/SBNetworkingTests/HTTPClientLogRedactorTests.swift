//
//  HTTPClientLogRedactorTests.swift
//  SBNetworking
//

import Foundation
import Testing
@testable import SBNetworking

@Suite
struct HTTPClientLogRedactorTests {

    // MARK: - Header redaction

    @Test
    func testCredentialHeaderValuesAreReplacedCaseInsensitively() {
        let headers = [
            "Authorization": "Bearer secret-jwt",
            "APIKEY": "anon-key",
            "S-Api-Key": "anon-key",
            "Content-Type": "application/json"
        ]

        let redacted = HTTPClientLogRedactor.redactedHeaders(headers)

        #expect(redacted["Authorization"] == HTTPClientLogRedactor.placeholder)
        #expect(redacted["APIKEY"] == HTTPClientLogRedactor.placeholder)
        #expect(redacted["S-Api-Key"] == HTTPClientLogRedactor.placeholder)
        #expect(redacted["Content-Type"] == "application/json")
    }

    @Test
    func testNilHeadersRedactToEmptyDictionary() {
        #expect(HTTPClientLogRedactor.redactedHeaders(nil).isEmpty)
    }

    // MARK: - Body sensitivity by path

    @Test
    func testAuthStylePathsAreBodySensitive() {
        let sensitive = [
            "https://example.supabase.co/functions/v1/auth-otp",
            "https://example.supabase.co/functions/v1/auth-verify",
            "https://example.supabase.co/functions/v1/auth-refresh",
            "https://example.supabase.co/auth/v1/token",
            "https://example.com/login",
            "https://example.com/signup"
        ]
        for urlString in sensitive {
            #expect(HTTPClientLogRedactor.isBodySensitive(for: URL(string: urlString)))
        }
    }

    @Test
    func testRegularPathsAreNotBodySensitive() {
        let regular = [
            "https://example.supabase.co/functions/v1/scan-start",
            "https://example.supabase.co/functions/v1/vehicle-resolve",
            "https://example.supabase.co/functions/v1/part-offers"
        ]
        for urlString in regular {
            #expect(!HTTPClientLogRedactor.isBodySensitive(for: URL(string: urlString)))
        }
    }

    @Test
    func testMissingURLIsTreatedAsSensitive() {
        #expect(HTTPClientLogRedactor.isBodySensitive(for: nil))
    }
}

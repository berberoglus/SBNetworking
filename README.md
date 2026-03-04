# SBNetworking

A lightweight, type-safe, and Swift-native HTTP networking library designed for modern iOS and macOS applications.

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2015.0+%20|%20macOS%2012.0+-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Features

- ✅ Clean, protocol-oriented architecture
- ✅ Type-safe request and response handling
- ✅ Comprehensive error handling
- ✅ Async/await support
- ✅ Auth token provider with automatic 401 retry and refresh
- ✅ Easily testable with built-in mocking capabilities
- ✅ Minimal dependencies (only Foundation)
- ✅ Customizable environment configurations

## Installation

### Swift Package Manager

Add SBNetworking to your project using Swift Package Manager by adding it to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/berberoglus/SBNetworking.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Go to File > Add Packages...
2. Enter the repository URL: `https://github.com/berberoglus/SBNetworking.git`
3. Specify the version requirements
4. Click "Add Package"

## Quick Start

### 1. Define Your API Environment

```swift
// Define your API environment
let environment = HTTPClientEnvironment(baseURL: "api.example.com")

// Create the HTTP client
let client = HTTPClient(client: HttpClientProtocolImpl(environment: environment))
```

### 2. Create an Endpoint

```swift
struct UserEndpoint: Endpoint {
    typealias ResponseType = User
    
    let userId: String
    
    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

struct User: Decodable {
    let id: String
    let name: String
    let email: String
}
```

### 3. Make a Request

```swift
do {
    let user = try await client.submitRequest(endpoint: UserEndpoint(userId: "123"))
    print("User: \(user?.name ?? "Unknown")")
} catch let error as HTTPClientError {
    print("Error: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Core Components

### Endpoint Protocol

The `Endpoint` protocol is the central abstraction for defining network requests:

```swift
public protocol Endpoint {
    associatedtype ResponseType: Decodable
    var path: String { get }
    var method: HTTPMethod { get }
    var headerFields: [String: String]? { get }
    var payload: Encodable? { get }
    var queryParameters: [String: String]? { get }
    var timeoutInterval: TimeInterval { get }
}
```

### HTTPClient

`HTTPClient` is responsible for executing requests and processing responses:

```swift
let client = HTTPClient(client: HttpClientProtocolImpl(environment: environment))
let response = try await client.submitRequest(endpoint: MyEndpoint())
```

### Error Handling

SBNetworking provides comprehensive error handling through the `HTTPClientError` enum:

```swift
do {
    let result = try await client.submitRequest(endpoint: endpoint)
    // Handle success
} catch HTTPClientError.notConnectedToInternet {
    // Handle no internet connection
} catch HTTPClientError.unauthorized {
    // Handle authentication failure
} catch HTTPClientError.serverError(let statusCode, let data) {
    // Handle server error with status code and response data
} catch {
    // Handle other errors
}
```

## Advanced Usage

### Authentication & Token Refresh

SBNetworking supports automatic auth header injection and 401 retry via the `AuthTokenProvider` protocol. When you provide an `AuthTokenProvider` to your `HttpClientProtocol` implementation, the client will:

- Add the `apikey` header from `apiKey` (for Supabase compatibility)
- Add `Authorization: Bearer {accessToken}` when present
- On 401 responses: call your `refresh()` method, then retry the request once

Override `refresh()` to enable 401 retry. The default implementation throws `HTTPClientError.unauthorized`.

```swift
// 1. Implement AuthTokenProvider (e.g. backed by Keychain)
final class KeychainTokenProvider: AuthTokenProvider {
    var accessToken: String? { /* read from Keychain */ }
    var refreshToken: String? { /* read from Keychain */ }
    var apiKey: String? { "your-supabase-anon-key" }
    func updateTokens(accessToken: String, refreshToken: String) {
        // Persist to Keychain
    }
    func refresh() async throws {
        // Call your auth refresh API, then:
        let newTokens = try await authClient.refresh()
        updateTokens(accessToken: newTokens.accessToken, refreshToken: newTokens.refreshToken)
    }
}

// 2. Inject via HttpClientProtocol
struct MyHttpClient: HttpClientProtocol {
    var urlSession = URLSession.shared
    var environment = HTTPClientEnvironment(baseURL: "your-api.com")
    var authTokenProvider: AuthTokenProvider? = KeychainTokenProvider()
}

// 3. Use as usual – auth headers and 401 retry are handled automatically
let client = HTTPClient(client: MyHttpClient())
let data = try await client.submitRequest(endpoint: ProtectedEndpoint())
```

Without `authTokenProvider` (or when `refresh()` throws by default), 401 responses throw `HTTPClientError.unauthorized` as before. The feature is fully backward compatible.

### Custom Headers

```swift
struct AuthenticatedEndpoint: Endpoint {
    typealias ResponseType = AuthResponse
    
    let token: String
    
    var path: String { "/secure-resource" }
    var method: HTTPMethod { .get }
    var headerFields: [String: String]? {
        ["Authorization": "Bearer \(token)"]
    }
}
```

### Request with Body

```swift
struct CreatePostEndpoint: Endpoint {
    typealias ResponseType = Post
    
    let postData: PostRequest
    
    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var payload: Encodable? { postData }
}

struct PostRequest: Encodable {
    let title: String
    let body: String
    let userId: Int
}
```

### Query Parameters

```swift
struct SearchEndpoint: Endpoint {
    typealias ResponseType = SearchResults
    
    let term: String
    let page: Int
    
    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var queryParameters: [String: String]? {
        ["q": term, "page": "\(page)"]
    }
}
```

## Testing

SBNetworking is designed with testability in mind. The library includes a `MockUrlProtocol` to make testing network code straightforward:

```swift
// Setup test environment
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockUrlProtocol.self]
let session = URLSession(configuration: config)

// Register mock response
let mockResponse = MyResponseModel(id: "123", name: "Test")
let mockData = try JSONEncoder().encode(mockResponse)
let url = URL(string: "https://api.example.com/resource")!
MockUrlProtocol.testSamples[url] = mockData

// Create client with mock session
let environment = HTTPClientEnvironment(baseURL: "api.example.com")
let client = HTTPClient(client: MockHttpClient(urlSession: session, environment: environment))

// Test your endpoint
let response = try await client.submitRequest(endpoint: MyEndpoint())
XCTAssertEqual(response?.id, "123")
```

### MockHttpClient Implementation

Here's an example implementation of `MockHttpClient` for testing:

```swift
struct MockHttpClient: HttpClientProtocol {
    let urlSession: URLSession
    let environment: HTTPClientEnvironment
    
    init(urlSession: URLSession, environment: HTTPClientEnvironment) {
        self.urlSession = urlSession
        self.environment = environment
    }
}

// Usage in tests
class NetworkTests: XCTestCase {
    var mockSession: URLSession!
    var client: HTTPClient!
    
    override func setUp() {
        super.setUp()
        
        // Create mock session with MockUrlProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockUrlProtocol.self]
        mockSession = URLSession(configuration: config)
        
        // Create environment and client
        let environment = HTTPClientEnvironment(baseURL: "api.example.com")
        let mockHttpClient = MockHttpClient(urlSession: mockSession, environment: environment)
        client = HTTPClient(client: mockHttpClient)
    }
    
    func testUserEndpoint() async throws {
        // Prepare mock data
        let mockUser = User(id: "123", name: "John Doe", email: "john@example.com")
        let mockData = try JSONEncoder().encode(mockUser)
        
        // Register the mock response
        let url = URL(string: "https://api.example.com/users/123")!
        MockUrlProtocol.testSamples[url] = mockData
        
        // Make the request
        let endpoint = UserEndpoint(userId: "123")
        let response = try await client.submitRequest(endpoint: endpoint)
        
        // Verify the response
        XCTAssertEqual(response?.id, "123")
        XCTAssertEqual(response?.name, "John Doe")
        XCTAssertEqual(response?.email, "john@example.com")
    }
}
```

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 15.0+

## License

SBNetworking is available under the MIT license. See the LICENSE file for more info. 

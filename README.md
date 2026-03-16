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
- ✅ Typed request-to-endpoint conversion with `RequestProtocol`
- ✅ DTO-to-model conversion support via `ResponseProtocol`

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

### 2. Create a Request and Endpoint

```swift
struct UserRequest: RequestProtocol {
    typealias EndpointType = UserEndpoint

    let userId: String

    func toEndpoint() -> UserEndpoint {
        UserEndpoint(userId: userId)
    }
}

struct UserEndpoint: Endpoint {
    typealias ResponseType = UserResponseDTO

    let userId: String

    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

struct UserResponseDTO: ResponseProtocol {
    typealias ModelType = User

    let id: String
    let name: String
    let email: String

    func toModel() -> User {
        User(id: id, name: name, email: email)
    }
}

struct User {
    let id: String
    let name: String
    let email: String
}
```

### 3. Make a Request

```swift
do {
    let response = try await client.submitRequest(request: UserRequest(userId: "123"))
    let user = response?.toModel()

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
    associatedtype ResponseType: ResponseProtocol
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

// Endpoint-based usage
let endpointResponse = try await client.submitRequest(endpoint: MyEndpoint())

// Request-based usage
let requestResponse = try await client.submitRequest(request: MyRequest())
```

### Request and Response Protocols

SBNetworking also supports a request-first flow using typed request and response abstractions:

```swift
public protocol EndpointConvertible {
    associatedtype EndpointType: Endpoint
    func toEndpoint() -> EndpointType
}

public protocol RequestProtocol: EndpointConvertible, Encodable, Sendable { }

public protocol ModelConvertible {
    associatedtype ModelType
    func toModel() -> ModelType
}

public protocol ResponseProtocol: Decodable, ModelConvertible, Sendable { }
```

This allows higher layers to create typed request objects, convert them into endpoints,
and decode transport DTOs that can be transformed into higher-level models.

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
    typealias ResponseType = AuthResponseDTO

    let token: String

    var path: String { "/secure-resource" }
    var method: HTTPMethod { .get }
    var headerFields: [String: String]? {
        ["Authorization": "Bearer \(token)"]
    }
}

struct AuthResponseDTO: ResponseProtocol {
    typealias ModelType = AuthResponse

    let token: String

    func toModel() -> AuthResponse {
        AuthResponse(token: token)
    }
}

struct AuthResponse {
    let token: String
}
```

### Request with Body

```swift
struct CreatePostRequest: RequestProtocol {
    typealias EndpointType = CreatePostEndpoint

    let title: String
    let body: String
    let userId: Int

    func toEndpoint() -> CreatePostEndpoint {
        CreatePostEndpoint(request: self)
    }
}

struct CreatePostEndpoint: Endpoint {
    typealias ResponseType = PostResponseDTO

    let request: CreatePostRequest

    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var payload: Encodable? { request }
}

struct PostResponseDTO: ResponseProtocol {
    typealias ModelType = Post

    let id: Int
    let title: String
    let body: String
    let userId: Int

    func toModel() -> Post {
        Post(id: id, title: title, body: body, userId: userId)
    }
}

struct Post {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}
```

### Query Parameters

```swift
struct SearchRequest: RequestProtocol {
    typealias EndpointType = SearchEndpoint

    let term: String
    let page: Int

    func toEndpoint() -> SearchEndpoint {
        SearchEndpoint(request: self)
    }
}

struct SearchEndpoint: Endpoint {
    typealias ResponseType = SearchResultsDTO

    let request: SearchRequest

    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var queryParameters: [String: String]? {
        ["q": request.term, "page": "\(request.page)"]
    }
}
```

## Testing

SBNetworking is designed with testability in mind. The library includes a `MockUrlProtocol` to make testing network code straightforward:

```swift
struct MyResponseDTO: ResponseProtocol {
    typealias ModelType = MyModel

    let id: String
    let name: String

    func toModel() -> MyModel {
        MyModel(id: id, name: name)
    }
}

struct MyModel {
    let id: String
    let name: String
}

// Setup test environment
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockUrlProtocol.self]
let session = URLSession(configuration: config)

// Register mock response
let mockResponse = MyResponseDTO(id: "123", name: "Test")
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
        let mockUser = MyResponseDTO(id: "123", name: "John Doe")
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
    }
}
```

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 15.0+

## License

SBNetworking is available under the MIT license. See the LICENSE file for more info.

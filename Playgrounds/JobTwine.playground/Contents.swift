import Foundation
import Combine

// MARK: - Q1: How to call Objective-C code dynamically from Swift using a selector?

class MyService: NSObject {
    @objc func fetchData() {
        print("Fetching data...")
    }

    @objc func process(value: String) {
        print("Processing: \(value)")
    }
}

let service = MyService()

// Call a no-argument method dynamically
let selector = #selector(MyService.fetchData)
service.perform(selector)

// Call with one argument
let processSelector = #selector(MyService.process(value:))
service.perform(processSelector, with: "Hello")

// Key points:
// - The target class must inherit from NSObject
// - Methods must be marked with @objc
// - Use #selector() for compile-time safety
// - perform(_:) returns Unmanaged<AnyObject>? — use .takeUnretainedValue() to get return value if needed


// MARK: - Q2: How to integrate a GraphQL API with a SwiftUI view?

// GraphQL requests are always POST with a JSON body containing "query" (and optionally "variables").
// Below is a plain URLSession approach (no third-party library needed).

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
}

func fetchGraphQL(query: String, url: URL) async throws -> Data {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = ["query": query]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}

// SwiftUI + ObservableObject usage (requires import SwiftUI in a real app):
//
// @MainActor
// class PostsViewModel: ObservableObject {
//     @Published var posts: [Post] = []
//     @Published var isLoading = false
//
//     func fetchPosts() async {
//         isLoading = true
//         defer { isLoading = false }
//         let url = URL(string: "https://api.example.com/graphql")!
//         let query = "{ posts { id title } }"
//         do {
//             let data = try await fetchGraphQL(query: query, url: url)
//             let result = try JSONDecoder().decode(GraphQLResponse<PostsData>.self, from: data)
//             posts = result.data?.posts ?? []
//         } catch {
//             print("Error: \(error)")
//         }
//     }
// }
//
// struct PostsView: View {
//     @StateObject private var viewModel = PostsViewModel()
//     var body: some View {
//         List(viewModel.posts) { post in Text(post.title) }
//             .task { await viewModel.fetchPosts() }
//     }
// }

// For Apollo iOS (add via SPM: https://github.com/apollographql/apollo-ios):
// apolloClient.fetch(query: PostsQuery()) { result in
//     switch result {
//     case .success(let graphQLResult): ...
//     case .failure(let error): ...
//     }
// }


// MARK: - Q3: How to mock URLSession using Combine?

// Step 1: Define a protocol so the mock can replace the real session
protocol URLSessionProtocol {
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

// Step 2: Extend URLSession to conform to URLSessionProtocol
extension URLSession: URLSessionProtocol {
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        let publisher: URLSession.DataTaskPublisher = dataTaskPublisher(for: request)
        return publisher.eraseToAnyPublisher()
    }
}

// Step 3: Create a mock session
struct MockURLSession: URLSessionProtocol {
    let responseData: Data
    let response: URLResponse
    let error: URLError?

    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        if let error {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        return Just((data: responseData, response: response))
            .setFailureType(to: URLError.self)
            .eraseToAnyPublisher()
    }
}

// Step 4: Service with injected session
struct User: Decodable {
    let id: Int
    let name: String
}

class APIService {
    private let session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    func fetchUser(id: Int) -> AnyPublisher<User, Error> {
        let request = URLRequest(url: URL(string: "https://api.example.com/users/\(id)")!)
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: User.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// Step 5: Use the mock in a test
let mockData = #"{"id": 1, "name": "Alice"}"#.data(using: .utf8)!
let mockResponse = HTTPURLResponse(
    url: URL(string: "https://api.example.com/users/1")!,
    statusCode: 200,
    httpVersion: nil,
    headerFields: nil
)!
let mockSession = MockURLSession(responseData: mockData, response: mockResponse, error: nil)
let apiService = APIService(session: mockSession)

var cancellables = Set<AnyCancellable>()
apiService.fetchUser(id: 1)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { user in
            print("Fetched user: \(user.name)") // Fetched user: Alice
        }
    )
    .store(in: &cancellables)

// Key points:
// - Protocol-based DI (Dependency Injection) lets you swap URLSession for a mock
// - Just + setFailureType simulates a successful response
// - Fail simulates a network error
// - Alternative: URLProtocol subclassing (works without protocol injection)


// MARK: - Q4: How to snapshot test a SwiftUI view for both light and dark mode simultaneously?

// Uses SnapshotTesting by Point-Free (add via SPM: https://github.com/pointfreeco/swift-snapshot-testing)
// This runs in XCTest, not a playground — shown here as reference code.

// import XCTest
// import SnapshotTesting
// import SwiftUI
//
// @MainActor
// final class MyViewSnapshotTests: XCTestCase {
//
//     func testLightAndDarkMode() {
//         let view = MyView()
//
//         // Light mode snapshot
//         assertSnapshot(
//             of: UIHostingController(rootView: view),
//             as: .image(traits: UITraitCollection(userInterfaceStyle: .light)),
//             named: "light"
//         )
//
//         // Dark mode snapshot
//         assertSnapshot(
//             of: UIHostingController(rootView: view),
//             as: .image(traits: UITraitCollection(userInterfaceStyle: .dark)),
//             named: "dark"
//         )
//     }
//
//     // Or test both modes in one call using a dictionary of strategies:
//     func testMyViewBothModes() {
//         let vc = UIHostingController(rootView: MyView())
//         assertSnapshots(
//             of: vc,
//             as: [
//                 "light": .image(traits: UITraitCollection(userInterfaceStyle: .light)),
//                 "dark":  .image(traits: UITraitCollection(userInterfaceStyle: .dark))
//             ]
//         )
//     }
// }

// Key points:
// - First run generates reference images in __Snapshots__ — commit them to source control
// - Subsequent runs compare against those references and fail if pixels differ
// - named: parameter distinguishes the two snapshots so both are stored separately
// - Set isRecording = true on the test to regenerate reference images after intentional UI changes
// - Works with UIHostingController to bridge SwiftUI into UIKit snapshot infrastructure


// MARK: - Q5: How to mock URLSession using async/await (no Combine)?

// Step 1: Define a protocol with an async throws signature
protocol URLSessionAsyncProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// Step 2: Extend URLSession to conform
extension URLSession: URLSessionAsyncProtocol {}

// Step 3: Create a mock session
struct MockURLSessionAsync: URLSessionAsyncProtocol {
    let responseData: Data
    let response: URLResponse
    let error: URLError?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error {
            throw error
        }
        return (responseData, response)
    }
}

// Step 4: Service using async/await
class APIServiceAsync {
    private let session: URLSessionAsyncProtocol

    init(session: URLSessionAsyncProtocol = URLSession.shared) {
        self.session = session
    }

    func fetchUser(id: Int) async throws -> User {
        let request = URLRequest(url: URL(string: "https://api.example.com/users/\(id)")!)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(User.self, from: data)
    }
}

// Step 5: Use the mock
let mockSessionAsync = MockURLSessionAsync(responseData: mockData, response: mockResponse, error: nil)
let apiServiceAsync = APIServiceAsync(session: mockSessionAsync)

Task {
    do {
        let user = try await apiServiceAsync.fetchUser(id: 1)
        print("Fetched user: \(user.name)") // Fetched user: Alice
    } catch {
        print("Error: \(error)")
    }
}

// Key points:
// - Same DI pattern as Combine but the protocol uses async throws instead of AnyPublisher
// - URLSession already has data(for:) so the extension conformance is empty
// - MockURLSessionAsync throws the error directly instead of using Fail
// - No cancellables needed — Task handles the async lifecycle
// - Prefer this approach in new code; use Combine only if the codebase already depends on it

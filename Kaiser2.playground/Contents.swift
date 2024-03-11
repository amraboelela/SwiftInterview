import UIKit

//## In swift create a network layer with an end point and using protocols and handling error and giving results
/*
struct Result<T> {
    let responseCode: Int,
    let responseModel: T
}

enum ResponseError: Error {
    case resultError(Int):
    case other
}

class HTTPUtil {
    static var shared = HTTPUtil()
    
    func endPoint1(url: URL, param1: String, param2: String, callback: @escaping () -> (Error?, String?)) {
        let session = URLSession()
        let request = URLRequest()
        //let url
        request.url = url
        request.httpMethod = "POST"
        let jsonRequest = "{\"param1\":\(param1), \"param2\":\(param2)}"
        request.httpBody = jsonRequest
        session.request = request
        session { response in
            switch response.statusCode {
            case 200:
                let result = response.body
                callback(nil, result)
            default:
                callback(ResponseError.resultError(response.statusCode), nil)
            }
        }.execute
    }
}*/

// From ChatGPT:

/*Creating a network layer in Swift involves a few key steps, including defining endpoints, creating a protocol for the network layer, handling requests, and processing responses and errors. Below is a simplified example to illustrate these concepts.
*/

// First, define an enum for endpoints:

enum APIEndpoint {
    case fetchPosts
    case fetchUser(userId: Int)

    var urlString: String {
        switch self {
        case .fetchPosts:
            return "https://jsonplaceholder.typicode.com/posts"
        case .fetchUser(let userId):
            return "https://jsonplaceholder.typicode.com/users/\(userId)"
        }
    }
}

// Next, create a protocol for the network layer:

protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(
        endpoint: APIEndpoint,
        completion: @escaping (Result<T, Error>) -> Void
    )
}

// Define some common network errors:

enum NetworkError: Error {
    case invalidURL
    case noData
}

// Now, implement the network service:

class NetworkService: NetworkServiceProtocol {
    func fetch<T: Decodable>(
        endpoint: APIEndpoint,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: endpoint.urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }

                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(NetworkError.invalidURL))
                }
            }
        }

        task.resume()
    }
}

// Finally, use the network service to fetch data:

struct Post: Codable {
    var time: Int
    var title: String
    var message: String
}

struct User: Codable {
    var username: String
    var firtName: String
    var lastName: String
}

let networkService = NetworkService()

networkService.fetch(endpoint: .fetchPosts) { (result: Result<[Post], Error>) in
    switch result {
    case .success(let posts):
        // Handle successful response with posts
        print(posts)
    case .failure(let error):
        // Handle error
        print(error.localizedDescription)
    }
}

networkService.fetch(endpoint: .fetchUser(userId: 1)) { (result: Result<User, Error>) in
    switch result {
    case .success(let user):
        // Handle successful response with user data
        print(user)
    case .failure(let error):
        // Handle error
        print(error.localizedDescription)
    }
}

/*
In this example, `Post` and `User` would be your model classes conforming to `Decodable`. You'll need to replace them with your actual data models.

This code provides a basic structure for a network layer using protocols and generics, allowing for flexibility and reusability. Error handling is also incorporated to manage common network issues.
*/

//## Using swift concurrency

// To implement a network layer using Swift's concurrency features, we'll use `async/await` along with `throws` to handle asynchronous network requests and error propagation. Here's a revised version of the network service using Swift Concurrency:

// Define the protocol for the network service:

protocol NetworkServiceProtocolSC {
    func fetch<T: Decodable>(endpoint: APIEndpoint) async throws -> T
}

// Implement the network service with Swift concurrency:

class NetworkServiceSC: NetworkServiceProtocolSC {
    func fetch<T: Decodable>(endpoint: APIEndpoint) async throws -> T {
        guard let url = URL(string: endpoint.urlString) else {
            throw NetworkError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Use the network service with Swift concurrency:

let networkServiceSC = NetworkServiceSC()

Task { @MainActor in
    do {
        let posts: [Post] = try await networkServiceSC.fetch(endpoint: .fetchPosts)
        // Handle successful response with posts
        print(posts)
    }
    catch {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                print("Invalid URL.")
            case .noData:
                print("No data received.")
            }
        } else {
            // Handle non-network errors
            print(error.localizedDescription)
        }
    }
    do {
        let user: User = try await networkServiceSC.fetch(endpoint: .fetchUser(userId: 1))
        // Handle successful response with user data
        print(user)
    } catch {
        // Handle error
        print(error.localizedDescription)
    }
}

// In this example, `Post` and `User` are your model types conforming to `Decodable`. Replace them with your actual model types.

// This implementation leverages Swift's concurrency model to simplify asynchronous network requests. The `fetch` method is marked with `async` and `throws`, indicating that it's an asynchronous function that can throw errors. The `Task` is used to call these asynchronous functions. This approach provides clearer and more concise code, especially for handling asynchronous tasks and errors.


//## return 2^2+4^2+6^2+8^2+10^2

func squareSum(numbers: [Int]) -> Int {
    return numbers.reduce(0) { current, number in
        if number % 2 == 0 {
            return current + number*number
        } else {
            return current
        }
    }
}

let numbers = [1,2,3,4,5,6,7,8,9,10]
squareSum(numbers: numbers)


protocol Shape {
    func area() -> Int
    func parimeter() -> Int
}

extension Shape {
    func parimeter() -> Int {
        return 0
    }
}

class Circle: Shape {
    var radius: Int
    
    func area() -> Int {
        return radius^2 * Double.pi
    }
    
    func parimeter() -> Int {
        return 2 * radius * Double.pi
    }
}

class Square: Shape {
    var length: Int
    
    func area() -> Int {
        return length * length
    }
    
    /*func parimeter() -> Int {
        return length * 4
    }*/
}

protocol CacheProtocol<V> {
    func setCapacity(capacity: Int)
    func setValue(key: String, v: V)
    func getValue(key: String) -> V
}

class Cache<V>: CacheProtocol {
    
    private struct PayLoad {
        var key: String
        var value: V
    }
    
    var capacity: Int
    var cache = [String: LinkdedListNode<PayLoad>]()
    var priority = LinkedList<PayLoad>()
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func setValue(key: String, v: V) {
        //let item = LinkdedListNode<PayLoad>(key: key, value: v)
        if let item = cache[key] {
            item.value.value = v
            priority.moveToHead(item)
        } else {
            let item = LinkdedListNode<PayLoad>(key: key, value: v)
            let node = priority.addHead(node: item)
            cache[key] = item
            
            if cache.count > capacity {
                let node = priority.removeTail()
                cache[node.key] = nil
            }
        }
    }
    
    func getValue(key: String, v: V) -> V {
        if let item = cache[key] {
            priority.moveToHead(item)
            return item.value.value
        }
    }
    
}

class LinkdedListNode<P> {
    var key: String
    var value: P
    
    var prev: LinkdedListNode?
    var next: LinkdedListNode?
}

class LinkdedList<P> {
    var head: LinkdedListNode?
    var tail: LinkdedListNode?
    
    func add(node: LinkdedListNode) {
        
    }
    
    func moveToHead(node: LinkdedListNode) {
        
    }
    
    func removeTail() {
        
    }
}

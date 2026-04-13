import Foundation

// MARK: - Generic function to add/concat 2 numbers or 2 strings

protocol Addable {
    static func + (lhs: Self, rhs: Self) -> Self
}

extension Int: Addable {}
extension Double: Addable {}
extension String: Addable {}

func addOrConcatenate<T: Addable>(_ a: T, _ b: T) -> T {
    return a + b
}

let sum = addOrConcatenate(5, 10)
let decimalSum = addOrConcatenate(5.5, 4.5)
let concatenatedString = addOrConcatenate("Hello, ", "World!")

print(sum)               // 15
print(decimalSum)        // 10.0
print(concatenatedString) // Hello, World!


// MARK: - Thread-safe Database access using OperationQueue

class Database {
    static let shared = Database()
    private let operationQueue = OperationQueue()

    init() {
        operationQueue.maxConcurrentOperationCount = 1 // serial queue
    }

    func performDatabaseOperation(_ operationBlock: @escaping () -> Void) {
        operationQueue.addOperation {
            operationBlock()
        }
    }

    func saveData(data: String) {
        // Save data to the database
    }

    func fetchData() -> String {
        return "data"
    }
}

Database.shared.performDatabaseOperation {
    Database.shared.saveData(data: "Sample Data")
}

Database.shared.performDatabaseOperation {
    let data = Database.shared.fetchData()
    print(data)
}


// MARK: - Network layer with endpoints, protocols, and error handling

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

enum NetworkError: Error {
    case invalidURL
    case noData
}

struct Post: Codable {
    var time: Int
    var title: String
    var message: String
}

struct User: Codable {
    var username: String
    var firstName: String
    var lastName: String
}

// Callback-based

protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(
        endpoint: APIEndpoint,
        completion: @escaping (Result<T, Error>) -> Void
    )
}

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
                if let error {
                    completion(.failure(error))
                    return
                }
                guard let data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}

let networkService = NetworkService()

networkService.fetch(endpoint: .fetchPosts) { (result: Result<[Post], Error>) in
    switch result {
    case .success(let posts): print(posts)
    case .failure(let error): print(error.localizedDescription)
    }
}

// async/await-based

protocol NetworkServiceProtocolSC {
    func fetch<T: Decodable>(endpoint: APIEndpoint) async throws -> T
}

class NetworkServiceSC: NetworkServiceProtocolSC {
    func fetch<T: Decodable>(endpoint: APIEndpoint) async throws -> T {
        guard let url = URL(string: endpoint.urlString) else {
            throw NetworkError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

let networkServiceSC = NetworkServiceSC()

Task { @MainActor in
    do {
        let posts: [Post] = try await networkServiceSC.fetch(endpoint: .fetchPosts)
        print(posts)
    } catch {
        print(error.localizedDescription)
    }

    do {
        let user: User = try await networkServiceSC.fetch(endpoint: .fetchUser(userId: 1))
        print(user)
    } catch {
        print(error.localizedDescription)
    }
}


// MARK: - Sum of squares of even numbers: 2^2+4^2+6^2+8^2+10^2

func squareSum(numbers: [Int]) -> Int {
    numbers.reduce(0) { current, number in
        number % 2 == 0 ? current + number * number : current
    }
}

let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
print(squareSum(numbers: numbers)) // 220

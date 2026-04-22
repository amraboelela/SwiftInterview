import Combine
import Foundation
import UIKit

// MARK: - Basic Combine subscribers

let myPublisher = [1, 2, 3, 4, 5].publisher

let mySubscriber = Subscribers.Sink<Int, Never> { completion in
    switch completion {
    case .finished: print("Finished")
    case .failure(let error): print("Received error: \(error)")
    }
} receiveValue: { value in
    print("Received value: \(value)")
}

let mySubscriber2 = Subscribers.Sink<Int, Never> { completion in
    switch completion {
    case .finished: print("mySubscriber2 Finished")
    case .failure(let error): print("mySubscriber2 Received error: \(error)")
    }
} receiveValue: { value in
    print("mySubscriber2 Received value: \(value)")
}

myPublisher.subscribe(mySubscriber)
myPublisher.subscribe(mySubscriber2)

// MARK: - Network request with Combine

struct Post: Codable {
    var id: Int
    var userId: Int
    var title: String
    var body: String
}

class ViewModel {
    private var cancellables = Set<AnyCancellable>()

    init() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Post].self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] model in
                    self?.handleNewModel(model)
                }
            )
            .store(in: &cancellables)
    }

    private func handleNewModel(_ model: [Post]) {
        print("Received model: \(model)")
    }
}

let viewModel = ViewModel()

// MARK: - POST request with async/await

struct User: Codable {
    var name: String
    var email: String
}

func loadUsers() async throws {
    guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(User(name: "John Doe", email: "johndoe@example.com"))
    let (data, _) = try await URLSession.shared.data(for: request)
    let user = try JSONDecoder().decode(User.self, from: data)
    print("Received user: \(user)")
}

Task {
    do {
        try await loadUsers()
    } catch {
        print("Error: \(error)")
    }
}

// MARK: - DispatchGroup

let dispatchGroup = DispatchGroup()

dispatchGroup.enter()
DispatchQueue.global().async {
    print("Task 1 is running")
    sleep(2)
    print("Task 1 is done")
    dispatchGroup.leave()
}

dispatchGroup.enter()
DispatchQueue.global().async {
    print("Task 2 is running")
    sleep(1)
    print("Task 2 is done")
    dispatchGroup.leave()
}

dispatchGroup.notify(queue: .main) {
    print("All tasks are completed")
}

// MARK: - @Published + Combine: ViewModel → ViewController

class TwisterViewModel {
    @Published var posts: [Post] = []

    init() {
        Task {
            try await Task.sleep(for: .seconds(4))
            posts = [Post(id: 1, userId: 1, title: "New Post", body: "Content of the new post")]
            try await Task.sleep(for: .seconds(2))
            posts = [Post(id: 2, userId: 2, title: "Post 2", body: "Content of post2")]
        }
    }
}

class TwisterViewController: UIViewController {
    var viewModel = TwisterViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.$posts
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.updateUI(with: $0)
            }
            .store(in: &cancellables)
    }

    private func updateUI(with posts: [Post]) {
        print("Updating UI for posts: \(posts)")
    }
}

let viewController = TwisterViewController()
viewController.viewDidLoad()

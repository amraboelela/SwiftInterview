import Combine

// Define a publisher
let myPublisher = [1, 2, 3, 4, 5].publisher

// Define a subscriber
let mySubscriber = Subscribers.Sink<Int, Never> { completion in
    switch completion {
    case .finished:
        print("Finished")
    case .failure(let error):
        print("Received error: \(error)")
    }
} receiveValue: { value in
    print("Received value: \(value)")
}

let mySubscriber2 = Subscribers.Sink<Int, Never> { completion in
    switch completion {
    case .finished:
        print("mySubscriber2 Finished")
    case .failure(let error):
        print("mySubscriber2 Received error: \(error)")
    }
} receiveValue: { value in
    print("mySubscriber2 Received value: \(value)")
}

// Connect the publisher and subscriber
myPublisher.subscribe(mySubscriber)
myPublisher.subscribe(mySubscriber2)

//## Give me an example

/*Certainly! Let's consider a practical example using Combine to fetch data from a network request and update the UI. This example will demonstrate how to use Combine's `URLSession` extension for making network requests, processing the received data, and handling errors.*/

import Combine
import Foundation

// Assuming you have a model for the JSON response
struct Post: Codable {
    var id: Int
    var userId: Int
    var title: String
    var body: String
}

class ViewModel {
    // A publisher that will emit updates of [Post]
    var myModelPublisher: AnyPublisher<[Post], Error>?

    // A cancellable set to store our subscriptions
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Set up the publisher
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        myModelPublisher = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data) // Map to data
            .decode(type: [Post].self, decoder: JSONDecoder()) // Decode into [Post]
            .receive(on: RunLoop.main) // Ensure we update on the main thread
            .eraseToAnyPublisher() // Convert to AnyPublisher

        // Start the subscription
        myModelPublisher?
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] model in
                self?.handleNewModel(model)
            })
            .store(in: &cancellables)
    }

    private func handleNewModel(_ model: [Post]) {
        // Update your UI or process the data
        print("Received model: \(model)")
    }
}

// Instantiate ViewModel
let viewModel = ViewModel()

/*
In this example:

- We have a `ViewModel` class that sets up a network request to fetch `[Post]` data.
- The `myModelPublisher` is a `URLSession.dataTaskPublisher` that fetches data from a URL.
- We use `map` to extract the `data` from the URL response.
- The data is then decoded from JSON into `[Post]` using `decode`.
- `receive(on: RunLoop.main)` ensures that the subscriber's closure is called on the main thread, which is crucial for UI updates.
- `sink` is used to handle the received values and completion events. The received values are processed in `handleNewModel`, and any errors are printed.
- The subscription is stored in `cancellables` to keep it alive.

Note: To run this code, you need to have a proper URL and a corresponding model (`Post`) that matches the JSON structure returned by that URL. This example is simplified for demonstration purposes and may require adjustments to work with real-world APIs. Additionally, remember to handle network errors and data processing according to your app's specific needs.
*/


//## how can i make a post request
/*
Certainly! Making a POST request without using Combine in Swift can be done using `URLSession`. Here's an example of how you can achieve this:

1. **Define Your Data Model**: Let's assume you have a model that you want to send in your POST request. For example:*/

struct User: Codable {
    var name: String
    var email: String
}

/*
2. **Create the POST Request**: Set up the URL, request, and the body of your POST request.*/

func loadUsers() {
    guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let newUser = User(name: "John Doe", email: "johndoe@example.com")
    request.httpBody = try? JSONEncoder().encode(newUser)
    
    /*
     3. **Perform the Request with URLSession**: Use `URLSession` to perform the request and handle the response in a completion handler.
     */
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // Check for errors
        if let error {
            print("Error: \(error)")
            return
        }
        
        // Check for valid data
        guard let data else { return }
        
        // Optionally, handle the response data
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            print("Received user: \(user)")
        } catch {
            print("Error decoding data: \(error)")
        }
    }
    
    task.resume()  // Don't forget to resume the task!
}

loadUsers()

/*
In this example, `URLSession.shared.dataTask` is used to create a task that sends the HTTP request. The completion handler is called when the request is complete, providing you with the data, response, and any errors.

The data received from the server is then decoded from JSON into your `User` model. It's important to handle possible errors at each step, including network errors, data availability, and JSON decoding errors.

This approach is straightforward and does not rely on any additional frameworks or libraries beyond what is available in standard Swift.
*/


//## How to group 2 dispatch tasks
/*
Grouping two dispatch tasks in Swift can be accomplished using `DispatchGroup`. This is particularly useful when you have multiple asynchronous tasks and you want to be notified when they are all complete. Here's how to do it:

1. **Create a DispatchGroup**: You start by creating an instance of `DispatchGroup`.

    let dispatchGroup = DispatchGroup()

2. **Enter the Group Before Each Task**: Before each task begins, you tell the dispatch group that a task is starting by calling `dispatchGroup.enter()`.

3. **Leave the Group After Each Task**: Once each task completes, you must call `dispatchGroup.leave()` to signal that this particular task is finished.

4. **Notify When All Tasks Are Complete**: You can use `dispatchGroup.notify` to run a closure after all the tasks have completed.

Here is an example with two asynchronous tasks:
*/

let dispatchGroup = DispatchGroup()

// First Task
dispatchGroup.enter()
DispatchQueue.global().async {
    // Do some work...
    print("Task 1 is running")
    // Simulate some asynchronous work
    sleep(2) // For demonstration purposes
    print("Task 1 is done")
    dispatchGroup.leave()
}

// Second Task
dispatchGroup.enter()
DispatchQueue.global().async {
    // Do some other work...
    print("Task 2 is running")
    // Simulate some asynchronous work
    sleep(1) // For demonstration purposes
    print("Task 2 is done")
    dispatchGroup.leave()
}

// Notify when all tasks are complete
dispatchGroup.notify(queue: DispatchQueue.main) {
    print("All tasks are completed")
}

// Continue with other work that doesn't depend on the completion of the two tasks...
/*
In this example, the `dispatchGroup.notify` block will be executed after both tasks have called `dispatchGroup.leave()`, indicating they are complete. The `notify` block runs on the main queue, but you can specify a different queue if needed. This method ensures that your code waits for the grouped tasks to finish without blocking the thread on which the tasks are enqueued.
 */


//## give me a combine example to publish var posts: [Post] from TwisterViewModel to TwisterViewController

/*Certainly! To demonstrate using Combine to publish a variable `posts: [Post]` from `TwisterViewModel` to `TwisterViewController`, I'll break down the process into steps. First, ensure that you have imported the Combine framework.

1. **Define Your Post Model**: I'll assume you have a `Post` model.
*/
/*
struct Post {
    // Your Post model properties
    var title: String
    var content: String
}*/

/*
2. **Create TwisterViewModel with a Published Property**:
*/

class TwisterViewModel {
    @Published var posts: [Post] = []
    
    // Other properties and methods of your ViewModel
    // ...
    init() {
        Task {
            sleep(4)
            posts = [Post(id: 1, userId: 1, title: "New Post", body: "Content of the new post")]
            sleep(2)
            posts = [Post(id: 2, userId: 2, title: "Post 2", body: "Content of post2")]
        }
    }
}

/*
    Here, `@Published` is a property wrapper provided by Combine, which creates a publisher for `posts`.

3. **TwisterViewController Subscribes to the ViewModel's Publisher**:

    In `TwisterViewController`, you'll want to keep a reference to any subscriptions to avoid them being deallocated. You can do this using an instance of `AnyCancellable`.
*/

import UIKit

class TwisterViewController: UIViewController {
    var viewModel = TwisterViewModel()
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeViewModel()
    }
    
    private func observeViewModel() {
        viewModel.$posts
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.updateUI(with: $0)
            }
            .store(in: &cancellables)
    }
    
    private func updateUI(with posts: [Post]) {
        // Update your UI with the posts
        // ...
        print("Updating UI for posts: \(posts)")
    }
}

/*
    - `viewModel.$posts` creates a publisher that emits values whenever `posts` is updated.
    - `receive(on: RunLoop.main)` ensures that the updates are received on the main thread, which is important for UI updates.
    - `sink` is used to subscribe to the publisher and provide a closure that gets called with the new values.
    - `store(in: &cancellables)` stores the subscription in a set of `AnyCancellable`, keeping the subscription alive.

Now, whenever `posts` in `TwisterViewModel` is updated, `TwisterViewController` will receive these updates and can act accordingly, such as updating the UI.

This example demonstrates a simple one-way binding from the ViewModel to the ViewController using Combine. Remember to import Combine in any file where you're using it, and be aware of thread safety when dealing with UI updates.
*/

//## How to test it

let viewController = TwisterViewController()

// Simulate ViewDidLoad
viewController.viewDidLoad()



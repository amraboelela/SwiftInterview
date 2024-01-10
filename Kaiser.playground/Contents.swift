import Foundation

// How to create a function in swift with generic type to add / concat 2 numbers or 2 strings?

// Creating a generic function in Swift that can handle both addition for numbers and concatenation for strings involves using generics along with protocol constraints. Swift doesn't have a single protocol that both `String` and numeric types like `Int`, `Double`, etc., conform to directly, but you can define a custom protocol and extend existing types to conform to this protocol.

// Here's an example of how you can achieve this:

// Define a custom protocol
protocol Addable {
    static func +(lhs: Self, rhs: Self) -> Self
}

// Extend existing types to conform to the Addable protocol
extension Int: Addable {}
extension Double: Addable {}
extension String: Addable {}

// Define a generic function
func addOrConcatenate<T: Addable>(_ a: T, _ b: T) -> T {
    return a + b
}

// Usage examples
let sum = addOrConcatenate(5, 10)        // Works with Int
let decimalSum = addOrConcatenate(5.5, 4.5)  // Works with Double
let concatenatedString = addOrConcatenate("Hello, ", "World!") // Works with String

print(sum)              // Output: 15
print(decimalSum)       // Output: 10.0
print(concatenatedString) // Output: "Hello, World!"


/*In this implementation:

1. A custom protocol `Addable` is defined, which requires any conforming type to implement the `+` operator.
2. Existing types like `Int`, `Double`, and `String` are extended to conform to the `Addable` protocol. Since these types already have implementations of the `+` operator, no additional implementation is needed.
3. A generic function `addOrConcatenate` is defined that takes two parameters of type `T`, where `T` conforms to `Addable`. This allows the function to use the `+` operator on these parameters.

This approach uses Swift's powerful type system and protocols to create a versatile function that can handle different types in a type-safe manner.
*/


// Using operation queue how to make sure that class Database is accessed safely from different threads?

/*To ensure that a class, like `Database`, is accessed safely from different threads in Swift, you can use an `OperationQueue`. An `OperationQueue` manages a queue of operations (`NSOperation` objects) executing them either serially or concurrently. When you want to guarantee thread safety for accessing and modifying a shared resource like a database, you should use a serial queue, which executes one operation at a time.

Here's a basic example of how you might implement this:
*/

import Foundation

class Database {
    static let shared = Database() // Singleton instance
    private let operationQueue = OperationQueue()

    init() {
        operationQueue.maxConcurrentOperationCount = 1 // Makes it a serial queue
    }

    func performDatabaseOperation(_ operationBlock: @escaping () -> Void) {
        operationQueue.addOperation {
            operationBlock()
        }
    }

    // Example of a database operation
    func saveData(data: String) {
        // Save data to the database
    }

    // Example of another database operation
    func fetchData() -> String {
        // Fetch data from the database
        return "data"
    }
}

// Usage
Database.shared.performDatabaseOperation {
    Database.shared.saveData(data: "Sample Data")
}

Database.shared.performDatabaseOperation {
    let data = Database.shared.fetchData()
    print(data)
}

/*
In this example:

- `Database` is a singleton class, ensuring that the same instance is used throughout the application.
- It contains an `OperationQueue` with `maxConcurrentOperationCount` set to 1, making it a serial queue.
- The `performDatabaseOperation` method takes a closure (`operationBlock`) and adds it to the operation queue. This method ensures that all database operations are executed serially, one at a time, regardless of which thread they are called from.
- `saveData` and `fetchData` are examples of database operations that you might want to perform. They should be executed through the `performDatabaseOperation` method to ensure thread safety.

By using this approach, you can safely access and modify your database from multiple threads without running into race conditions or other concurrency-related issues.
*/

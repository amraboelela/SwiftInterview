# IMCS Group Assessment Prep

> Questions already covered in `General/` are excluded. See Swift.md, iOS.md, SwiftUI.md, Database.md, XCUI.md for those.

---

## Topics to Expect
1. Swift & iOS fundamentals
2. Memory management & ARC
3. Concurrency (GCD, async/await, actors)
4. Architecture patterns (MVVM, MVC, VIPER)
5. Data structures & algorithms
6. System design
7. Networking & APIs
8. Testing (XCTest, XCUITest)
9. SwiftUI vs UIKit
10. General software engineering principles

---

## 1. Swift Fundamentals

**Q: What is `defer` in Swift?**

A: Executes a block of code just before the current scope exits, regardless of how it exits. Useful for cleanup (e.g., closing files, releasing locks).

**Q: What is `@escaping` closure?**

A: A closure marked `@escaping` outlives the function it's passed to (e.g., stored for async use). Non-escaping closures are called within the function's lifetime.

**Q: What is the difference between `map`, `flatMap`, and `compactMap`?**

A:
- `map` — transforms each element, returns same count
- `flatMap` — flattens nested sequences
- `compactMap` — transforms and removes `nil` results

**Q: How does `flatMap` work? Give an example.**

A: `flatMap` transforms each element with a closure that returns a sequence, then flattens all resulting sequences into a single array. It's like `map` followed by `joined()`.

```swift
let words = [["Hello", "World"], ["Swift", "is", "fun"]]
let flat = words.flatMap { $0 }
// ["Hello", "World", "Swift", "is", "fun"]

// Compared to map — produces nested arrays:
let nested = words.map { $0 }
// [["Hello", "World"], ["Swift", "is", "fun"]]
```

Another common use — extracting values from nested optionals or arrays of arrays:

```swift
let numbers = [[1, 2, 3], [4, 5], [6]]
let doubled = numbers.flatMap { $0 }.map { $0 * 2 }
// [2, 4, 6, 8, 10, 12]
```

> Note: `flatMap` on optionals was renamed to `compactMap` in Swift 4.1 to make intent clearer. Use `compactMap` to unwrap and filter nils, `flatMap` for flattening sequences.

---

## 2. Swift Advanced

**Q: What is Protocol-Oriented Programming (POP)?**

A: A Swift paradigm favoring protocol composition over class inheritance. Protocols define capabilities; types conform to multiple protocols. Protocol extensions provide default implementations. Preferred over subclassing because structs can participate and avoids deep inheritance hierarchies.

```swift
protocol Flyable { func fly() }
protocol Swimmable { func swim() }
extension Flyable { func fly() { print("flying") } }

struct Duck: Flyable, Swimmable {
    func swim() { print("swimming") }
}
```

**Q: What are generics in Swift and why use them?**

A: Generics let you write flexible, reusable functions and types that work with any type satisfying given constraints. Avoids code duplication without sacrificing type safety.

```swift
func swap<T>(_ a: inout T, _ b: inout T) {
    let temp = a; a = b; b = temp
}
```

**Q: What are associated types in protocols?**

A: Placeholder types defined in a protocol that conforming types specify concretely. Similar to generics but at the protocol level.

```swift
protocol Container {
    associatedtype Item
    func add(_ item: Item)
    func get(at index: Int) -> Item
}
```

**Q: What is Swift's `Result` type?**

A: An enum with `.success(Value)` and `.failure(Error)` cases, used to represent the outcome of an operation that can fail. Common in completion-handler APIs before async/await.

```swift
func fetchUser(completion: (Result<User, Error>) -> Void) { ... }

fetchUser { result in
    switch result {
    case .success(let user): print(user.name)
    case .failure(let error): print(error)
    }
}
```

**Q: What is the difference between `throws` and `rethrows`?**

A: `throws` means the function itself can throw. `rethrows` means the function only throws if a closure passed to it throws — it doesn't introduce new errors on its own. `map`, `filter`, and `forEach` use `rethrows`.

**Q: What are `willSet` and `didSet`?**

A: Property observers called just before (`willSet`) and just after (`didSet`) a stored property's value changes. Useful for side effects like updating UI or validating values.

```swift
var score: Int = 0 {
    didSet { label.text = "\(score)" }
}
```

**Q: What is a `lazy` property?**

A: A stored property whose initial value is computed only the first time it's accessed. Useful for expensive initialization that may not be needed. Must be `var` because it's mutated on first access.

```swift
lazy var parser = JSONDecoder()
```

**Q: What is the difference between `any` and `some` in Swift?**

A:
- `some Protocol` — opaque type: the concrete type is fixed at compile time, known to the compiler but hidden from the caller. More performant.
- `any Protocol` — existential type (Swift 5.7+): the concrete type can vary at runtime. Incurs a performance cost due to boxing.

```swift
func makeShape() -> some Shape { Circle() }   // always Circle
func draw(_ shape: any Shape) { ... }          // any conforming type
```

**Q: What is `@discardableResult`?**

A: Suppresses the compiler warning when a function's return value is unused. Useful for functions that return a value as a convenience but are often called for their side effects.

```swift
@discardableResult
func save() -> Bool { ... }

save() // no warning even though return value is ignored
```

---

## 3. Concurrency

**Q: What is the difference between serial and concurrent queues?**

A: Serial queues execute tasks one at a time in order. Concurrent queues execute multiple tasks simultaneously.

**Q: What is a data race?**

A: When two threads access the same memory simultaneously and at least one is a write, without synchronization — leads to undefined behavior. Prevent with actors, serial queues, or locks.

**Q: What is an Actor in Swift?**

A: A reference type that protects its mutable state from data races by ensuring only one task accesses its state at a time. Introduced in Swift 5.5.

**Q: What is `MainActor`?**

A: A global actor that ensures code runs on the main thread. Use `@MainActor` on classes or functions that must update UI.

**Q: What is `Sendable` in Swift?**

A: A protocol marking types safe to share across concurrency boundaries (actors, tasks). Value types (structs, enums) are implicitly `Sendable` if all their stored properties are. Classes must be explicitly marked and typically require internal synchronization.

---

## 4. Architecture Patterns

**Q: What is Dependency Injection?**

A: Passing dependencies into an object rather than having it create them. Improves testability and decoupling. Can be done via initializer injection, property injection, or a DI container.

**Q: What is the Coordinator pattern?**

A: Separates navigation logic from ViewControllers. A Coordinator object handles routing between screens, keeping ViewControllers decoupled from each other.

---

## 5. iOS System & Storage

**Q: What is the difference between Keychain and UserDefaults?**

A:
- **UserDefaults** — lightweight key-value store for non-sensitive preferences (settings, flags). Not encrypted, visible in backups.
- **Keychain** — secure, encrypted storage for sensitive data (passwords, tokens, certificates). Persists across app reinstalls.

**Q: What is the difference between `NSCache` and `Dictionary` for in-memory caching?**

A: `NSCache` automatically evicts entries under memory pressure and is thread-safe. `Dictionary` holds all entries indefinitely and requires manual synchronization for thread safety. Use `NSCache` for image or data caches.

**Q: What are Push Notifications (APNs)?**

A: Apple Push Notification service delivers remote notifications to devices. Flow: app registers → APNs returns device token → server sends payload to APNs with token → APNs delivers to device. Requires entitlement and user permission.

**Q: What is a thread-safe Singleton in Swift?**

A: Using a `static let` constant is the simplest thread-safe singleton — Swift guarantees it's initialized once lazily using `dispatch_once` internally.

```swift
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
}
```

For mutable shared state, protect it with an actor:

```swift
actor NetworkManager {
    static let shared = NetworkManager()
    private init() {}
}
```

**Q: What are background tasks in iOS and when do you use them?**

A: iOS limits background execution. Use `BGTaskScheduler` (iOS 13+) to schedule `BGProcessingTask` (long work, requires charging) or `BGAppRefreshTask` (short refresh). Register in `Info.plist` and schedule in `applicationDidEnterBackground`.

**Q: What is the difference between frame and bounds in UIKit?**

A: `frame` is the view's rectangle in its **parent's** coordinate system. `bounds` is the view's rectangle in its **own** coordinate system (origin is usually (0,0)). Changing `bounds.origin` scrolls the content (as UIScrollView does).

**Q: What is `viewDidLoad` vs `viewWillAppear`?**

A: `viewDidLoad` is called once after the view is loaded into memory — use it for one-time setup. `viewWillAppear` is called every time the view is about to appear on screen — use it for refreshing data or updating UI that may have changed while the view was off-screen.

**Q: What is `@objc` and when is it needed?**

A: Exposes Swift declarations to Objective-C runtime. Required for: selectors (`#selector`), delegates conforming to `NSObject`-based protocols, KVO/KVC, and interoperability with UIKit APIs that use Obj-C under the hood.

---

## 6. Data Structures & Algorithms

**Q: What is the difference between a stack and a queue?**

A: Stack is LIFO (Last In First Out). Queue is FIFO (First In First Out).

**Q: What is a hash table and what is its time complexity?**

A: Maps keys to values using a hash function. Average O(1) for insert, lookup, delete. Worst case O(n) with collisions.

**Q: What is the time complexity of binary search?**

A: O(log n) — requires a sorted array. Halves the search space each iteration.

**Q: What is the difference between DFS and BFS?**

A: DFS (Depth-First Search) explores as far as possible down a branch before backtracking — uses a stack. BFS (Breadth-First Search) explores all neighbors level by level — uses a queue.

**Q: What is dynamic programming?**

A: Breaking a problem into overlapping subproblems and caching results (memoization) to avoid redundant computation. Classic examples: Fibonacci, Knapsack, Longest Common Subsequence.

**Q: How do you detect a cycle in a linked list?**

A: Floyd's cycle detection (fast/slow pointers). Move slow pointer by 1, fast pointer by 2. If they meet, there's a cycle.

**Q: How do you reverse a string in Swift?**

```swift
let reversed = String("hello".reversed())
```

**Q: How do you find duplicates in an array?**

```swift
func findDuplicates(_ arr: [Int]) -> [Int] {
    var seen = Set<Int>()
    var duplicates = Set<Int>()
    for num in arr {
        if !seen.insert(num).inserted { duplicates.insert(num) }
    }
    return Array(duplicates)
}
```

---

## 7. System Design

**Q: What is REST vs GraphQL?**

A: REST uses fixed endpoints per resource; over/under-fetching is common. GraphQL uses a single endpoint; clients request exactly the fields they need — more efficient for complex data graphs.

**Q: How would you scale a mobile backend API?**

A: Load balancer → stateless API servers → cache layer (Redis) → database with read replicas. Use CDN for static assets. Horizontal scaling for API tier.

**Q: How would you design a device management system for enterprise?**

A:
- MDM (Mobile Device Management) backend with device enrollment API
- Client app polls for compliance status, device assignments
- Manager dashboard with RBAC (role-based access control)
- Push notifications via APNs for policy changes
- Audit logging for compliance tracking

**Q: How would you design a file sync system (personal vs work directories)?**

A:
- Use a rules engine to classify files by metadata (owner, tags, file path)
- Personal files sync to user's personal cloud (iCloud personal)
- Work files sync to enterprise storage (internal drives or work iCloud)
- Track sync state in a local DB (SQLite/CoreData)
- Handle conflicts with timestamp or version vector strategy

---

## 8. General Engineering

**Q: What is SOLID?**

A:
- **S** — Single Responsibility: one reason to change
- **O** — Open/Closed: open for extension, closed for modification
- **L** — Liskov Substitution: subtypes must be substitutable for base types
- **I** — Interface Segregation: no client should depend on methods it doesn't use
- **D** — Dependency Inversion: depend on abstractions, not concretions

**Q: What is Git rebase vs merge?**

A: Merge creates a merge commit combining two branches. Rebase rewrites commit history by replaying commits on top of another branch — cleaner history but rewrites SHA hashes (avoid on shared branches).

---

## 9. Networking

**Q: How do you handle API errors gracefully?**

A: Use `do/catch` with `async throws`, map HTTP status codes to typed errors, show user-friendly error messages. Never crash on network failure.

---

## 10. Testing

**Q: What is Test-Driven Development (TDD)?**

A: Write a failing test first, then write the minimum code to make it pass, then refactor. Ensures code is testable by design.

---

## Tips for the Assessment
- Read each question carefully — Glider often includes tricky multiple-choice options
- For code output questions, trace through manually before selecting
- Time box: ~2 min per question (75 min / 38 questions)
- Swift syntax questions often test optionals, closures, and type inference edge cases
- Algorithm questions likely focus on arrays, strings, and basic tree/graph traversal

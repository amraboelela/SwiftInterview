# Swift questions

## Can you explain the concept of optionals in Swift? How are they used, and when would you use guard statements?

Optionals are a fundamental concept in Swift that allows variables to have a "no-value" state. This is particularly useful for scenarios where a value might be absent, either because it hasn't been set yet or because it doesn't exist.
 
- Force Unwrapping: To use the value inside an optional, you "force unwrap" it using !. However, this should be done cautiously, as it can lead to a runtime crash if the optional is nil.
- Conditional Unwrapping (if let): A safer way to unwrap optionals is using if let or guard let statements, which check for the presence of a value before unwrapping.

### When to Use Guard Statements:

- Early Exit in Functions: guard statements are often used for early exit from functions or methods when a certain condition is not met.
- Clarity and Readability: guard statements make the code more readable by explicitly stating the conditions under which execution should continue.

## What is the difference between a struct and a class in Swift?

A struct is a value type, while a class is a reference type. This means that when you copy a struct, you create a new copy of the struct's data. When you copy a class, you create a new reference to the class's data.

Structs are typically used to represent small, immutable data structures, such as points, sizes, and rectangles. Classes are typically used to represent larger, mutable data structures, such as view controllers and models.

## What is the difference between a strong reference, a weak reference, and an unowned reference?

A strong reference is a reference that keeps the object it points to alive. A weak reference is a reference that does not keep the object it points to alive. An unowned reference is similar to a weak reference, but it does not automatically become nil if the object it points to is deallocated.

Strong references are typically used when you need to ensure that an object remains alive until you are finished with it. Weak references are typically used when you do not want to prevent an object from being deallocated, but you still need to be able to access it if it is still alive. Unowned references are typically used when you know that the object you are pointing to will not be deallocated before you are finished with it.

## What is @autoclosure in Swift?

In Swift, @autoclosure is an attribute used with function parameters to automatically convert an expression into a closure. This can be particularly useful in cases where you want to delay the evaluation of an expression until it is actually needed. The @autoclosure attribute allows you to pass a closure that contains the code you want to execute later, but the syntax is more concise.

Here's a simple example to illustrate the use of @autoclosure:

```swift
func printMessage(messageProvider: @autoclosure () -> String) {
    print(messageProvider())
}

// Usage
printMessage(messageProvider: "Hello, World!")
```

In this example, the printMessage function takes a closure with the type () -> String as its parameter, but the @autoclosure attribute allows you to call this function with a simple string literal instead of a full closure. The closure is created implicitly, and the expression is only evaluated when it's invoked inside the function with messageProvider().

Without `@autoclosure`, callers would need to pass an explicit closure `{ return "Hello, World!" }`. Use `@autoclosure` for simple, side-effect-free expressions where delayed evaluation is safe.

## What is the difference between GCD and Swift Concurrency?

Both manage concurrent execution, but Swift Concurrency is the modern approach and GCD is the legacy one.

| | GCD | Swift Concurrency |
|---|---|---|
| **API style** | C-based, closure callbacks | Native Swift, async/await |
| **Thread management** | Manual (you pick the queue) | Cooperative thread pool managed by the runtime |
| **Cancellation** | No built-in support | Structured via `Task` and `TaskGroup` |
| **Data safety** | No compile-time guarantees | `actor` and `Sendable` enforced by the compiler |
| **Parallel work** | `DispatchGroup` + `DispatchQueue.concurrentPerform` | `async let` or `TaskGroup` |

```swift
// GCD (legacy)
DispatchQueue.global().async {
    let result = heavyWork()
    DispatchQueue.main.async { self.update(result) }
}

// Swift Concurrency (modern)
Task {
    let result = await heavyWork()
    await MainActor.run { update(result) }
}
```

Prefer Swift Concurrency for new code. GCD still appears in UIKit internals and older codebases.

## How to identify and fix memory leaks in Swift?

Identifying and fixing memory leaks in Swift, especially in iOS development, is crucial for maintaining the performance and reliability of your application. Memory leaks happen when allocated memory is not freed up, leading to increased memory usage and potential app crashes.

### Identifying Memory Leaks

1. **Xcode Instruments**:
   - Use the **Leaks** and **Allocations** tools in Instruments to detect memory leaks.
   - Run your app with Instruments attached and monitor the memory usage. Look for objects that should have been deallocated but are still in memory.
   - The **Leaks** instrument can help pinpoint where leaks are occurring.
2. **Xcode Memory Graph Debugger**:
   - Xcode's Memory Graph Debugger can visually show you the relationships between objects in memory.
   - It's useful for identifying retain cycles and reference count issues.
   - Activate the Memory Graph Debugger while your app is running in the Debug area.
3. **Code Analysis**:
   - Manually review your code, especially for closures and delegate patterns, as they are common sources of retain cycles.
   - Look for places where `weak` or `unowned` should be used to prevent strong reference cycles.
4. **Automated Testing**:
   - Write unit tests to ensure objects are deallocated as expected.

### Common Causes of Memory Leaks

1. **Retain Cycles**:
   - Occur when two or more objects hold strong references to each other, preventing ARC from deallocating them.
   - Common in closures and delegation.
2. **Singletons and Global Variables**:
   - Improper use of singletons or global variables can lead to memory that never gets released.
3. **Notifications and Observers**:
   - Forgetting to remove an object as an observer can lead to leaks.

### Fixing Memory Leaks

1. **Breaking Retain Cycles**: Use `weak` for delegates and in closures where `self` could be nil; use `unowned` only when you're certain the reference outlives the closure.

   ```swift
   class MyClass {
       weak var delegate: MyDelegate?
   }

   // Closure capture list
   Task { [weak self] in
       guard let self else { return }
       await self.doWork()
   }
   ```

2. **Swift Concurrency and retain cycles**: `Task { }` bodies capture `self` strongly by default. Always use `[weak self]` in detached or long-lived tasks, then guard at the start.
3. **Observers**: With Combine, store `AnyCancellable` in a `Set<AnyCancellable>` — cancellation and deallocation are automatic when the owner is deallocated. With NotificationCenter in UIKit, remove observers in `deinit`:

   ```swift
   deinit {
       NotificationCenter.default.removeObserver(self)
   }
   ```

4. **Testing and Profiling**: Use Instruments (Leaks + Allocations) and Xcode's Memory Graph Debugger. Write `addTeardownBlock` assertions in XCTest to verify objects deallocate after each test.

## Combine vs Swift Concurrency — when do you use each?

Combine (iOS 13+) is a functional reactive framework for working with event streams. Its key concepts: **Publishers** emit values over time, **Subscribers** consume them, **Operators** (`map`, `filter`, `debounce`, etc.) transform streams, **Subjects** (`PassthroughSubject`, `CurrentValueSubject`) inject values imperatively, and `AnyCancellable` manages subscription lifetime.

```swift
$searchText
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .removeDuplicates()
    .sink { [weak self] query in self?.search(query) }
    .store(in: &cancellables)
```

**Swift Concurrency** (`async/await` + `AsyncSequence`) is now preferred for most new code. It's simpler, compiler-checked for data races, and doesn't require managing `AnyCancellable` lifetimes.

```swift
// AsyncStream wraps URLSession.bytes into a download-progress sequence (0–100%)
func downloadProgress(from url: URL) -> AsyncStream<Int> {
    AsyncStream { continuation in
        Task {
            do {
                let (bytes, response) = try await URLSession.shared.bytes(from: url)
                let total = response.expectedContentLength
                var received: Int64 = 0
                for try await line in bytes.lines {
                    received += Int64(line.utf8.count + 1)
                    guard total > 0 else { continue }
                    continuation.yield(min(Int(received * 100 / total), 99))
                }
                continuation.yield(100)
                continuation.finish()
            } catch {
                continuation.finish()
            }
        }
    }
}

// Usage
for await percent in downloadProgress(from: url) {
    updateProgressBar(percent)
}
```

**When to still use Combine:**
- `@Published` + `ObservableObject` in SwiftUI (though `@Observable` macro from iOS 17 reduces this need)
- Operators like `debounce`, `throttle`, `combineLatest`, and `zip` — no direct async/await equivalent
- Existing codebases already built on Combine

**When to prefer Swift Concurrency:**
- One-shot async operations (network calls, file I/O)
- Structured task hierarchies with cancellation
- Anything new in Swift 5.5+

## Will the app crash if an async throwing function throws inside a Task?

No — but the error is silently swallowed.

When you write:

```swift
Task {
    try await loadUsers()
}
```

...and `loadUsers()` throws, the Task catches the error internally and simply marks itself as failed. The app keeps running, nothing is printed, and you get no indication that anything went wrong. This is a common gotcha.

### Compare the three behaviors:

**1. `try` inside Task with no catch — silent failure, app continues:**
```swift
Task {
    try await loadUsers()   // error? Task fails quietly, app lives on
}
```

**2. `try!` — guaranteed crash:**
```swift
Task {
    try! await loadUsers()  // error? Fatal error, app crashes immediately
}
```

**3. `do/catch` inside Task — proper error handling:**
```swift
Task {
    do {
        try await loadUsers()
    } catch {
        print("Error: \(error)")  // error is caught and handled gracefully
    }
}
```

Always use option 3 in production code. Option 1 is acceptable in playgrounds or throwaway scripts where you know the call will succeed. Option 2 should only be used when a failure is truly impossible (e.g. hardcoded valid data) — otherwise it's a ticking time bomb.

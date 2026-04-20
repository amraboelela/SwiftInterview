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

## `await MainActor.run { }` vs `Task { @MainActor in }`

Both hop execution to the main actor, but they behave very differently.

**`await MainActor.run { }`** — suspends the current task, runs the closure on the main actor, then resumes the caller. The caller waits for the result. This is structured concurrency.

```swift
let result = await MainActor.run { computeOnMain() }
```

**`Task { @MainActor in }`** — creates a new unstructured task that runs on the main actor. The caller does NOT wait — it's fire-and-forget unless you explicitly `.value` it.

```swift
Task { @MainActor in update(result) }  // fire-and-forget
await Task { @MainActor in update(result) }.value  // caller waits
```

### When to use which

**Use `await MainActor.run { }`** when you need to hop to the main actor inline inside an existing async task and wait for the result before continuing.

**Use `Task { @MainActor in }`** when you want to dispatch work to the main actor without blocking the current task (e.g. from a background actor or non-async context).

### The modern Swift 6 preferred pattern

If you own the function, annotate it `@MainActor` directly and call it with `await`. No `MainActor.run` needed:

```swift
@MainActor func update(_ result: SomeType) { ... }

// In an async context:
await update(result)
```

This is the cleanest approach. `await MainActor.run { }` is a workaround for when you can't annotate the function (e.g. a closure or third-party API).

## `@MainActor` vs Main Thread

The main thread and `@MainActor` are closely related but not the same concept.

**Main thread** is an OS-level concept — a specific thread managed by the operating system where UIKit and AppKit expect UI updates to happen. You access it via GCD: `DispatchQueue.main.async { }`.

**`@MainActor`** is a Swift concurrency concept — a global actor that serializes execution and guarantees its code runs on the main thread. It is enforced at compile time by the Swift type system.

### Key differences

| | Main Thread (GCD) | `@MainActor` |
|---|---|---|
| **Enforcement** | Runtime only | Compile time + runtime |
| **Data safety** | No guarantees | Compiler prevents data races |
| **Usage** | `DispatchQueue.main.async` | `@MainActor` annotation or `await MainActor.run` |
| **Cancellation** | None | Cooperative via Swift Concurrency |
| **Interop** | Works everywhere | Requires Swift Concurrency context |

### Under the hood

`@MainActor` always dispatches to the main thread — they share the same underlying serial queue (`DispatchQueue.main`). The difference is that `@MainActor` adds compiler-enforced isolation on top.

```swift
// GCD — runtime-only, no compile-time safety
DispatchQueue.main.async {
    self.label.text = "done"
}

// @MainActor — compiler ensures this only runs on main actor
@MainActor func updateLabel() {
    label.text = "done"
}
```

### When to use which

- Use `@MainActor` for all new Swift Concurrency code — you get compile-time data race protection for free.
- Use `DispatchQueue.main` only when working with legacy code, Objective-C APIs, or GCD-based systems that can't adopt Swift Concurrency.
- Annotate your `ViewModel` or `ObservableObject` with `@MainActor` to ensure all UI-bound state is always updated on the main actor without manual dispatching.

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var title = ""

    func load() async {
        let text = await fetchTitle()
        title = text  // safe — already on MainActor
    }
}
```

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

### Why `.store(in:)` must come after `.sink`

`.sink` returns an `AnyCancellable`. If you don't immediately store it, it is deallocated at the end of the expression — which **cancels the subscription right away** and your sink never receives any values.

`.store(in: &cancellables)` is always the last call in the chain, called directly on the `AnyCancellable` that `.sink` (or `.assign`) returns.

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

## Why does `AsyncStream` have a synchronous closure if it's async?

It feels contradictory, but the design is intentional.

The closure is the **setup** phase — it runs once synchronously to let you configure how values will be produced (start a Task, register a callback, set up a timer). It is not the producer itself.

The **actual async streaming** happens through the `continuation` — which you call from wherever you want, including inside an async `Task`, a callback, or a delegate method:

```swift
// From an async Task
AsyncStream { continuation in
    Task { await fetchValues(continuation) }
}

// From a callback/delegate
AsyncStream { continuation in
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        continuation.yield(Date())
    }
}
```

### Can `Timer` be used with async/await?

`Timer` has no native `async/await` API, but Combine bridges it via `.values`:

```swift
for await _ in Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().values {
    print(Date())
}
```

`.values` converts the Combine publisher into an `AsyncSequence` so you can consume it with `for await`. Under the hood it still uses the `Timer` object.

The pure Swift Concurrency alternative is `AsyncStream` + `Task.sleep`:

```swift
func timerStream(interval: Duration) -> AsyncStream<Date> {
    AsyncStream { continuation in
        Task {
            while true {
                continuation.yield(Date())
                try? await Task.sleep(for: interval)
            }
        }
    }
}
```

So `AsyncStream` is async from the **consumer's** perspective (`for await value in stream`). The setup closure is sync because it just needs to wire up the source — not produce values itself.

This also explains why you need `Task { }` inside the closure — to get an async context so you can use `await`:

```swift
AsyncStream { continuation in
    // ❌ can't use await here — this closure is sync

    Task {
        // ✅ async context — await works here
        let (bytes, _) = try await URLSession.shared.bytes(from: url)
        continuation.yield(...)
        continuation.finish()
    }
}
```

## `AsyncSequence` vs `AsyncStream`

**`AsyncSequence`** is a protocol — it defines something you can iterate over with `for await`. Like how `Sequence` works for synchronous iteration.

**`AsyncStream`** is a concrete type that **conforms to `AsyncSequence`** — it's the easiest way to create your own async sequence by pushing values through a `continuation`.

```swift
// AsyncSequence — protocol, you implement it yourself
struct Countdown: AsyncSequence {
    typealias Element = Int
    func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }

    struct AsyncIterator: AsyncIteratorProtocol {
        var count = 3
        mutating func next() async -> Int? {
            guard count > 0 else { return nil }
            defer { count -= 1 }
            return count
        }
    }
}

// AsyncStream — concrete, simpler to create
let countdown = AsyncStream<Int> { continuation in
    Task {
        for i in stride(from: 3, to: 0, by: -1) {
            continuation.yield(i)
        }
        continuation.finish()
    }
}
```

| | `AsyncSequence` | `AsyncStream` |
|---|---|---|
| **Type** | Protocol | Concrete type |
| **Use when** | Building a reusable custom type | Quick one-off stream from a callback or Task |
| **Complexity** | More boilerplate | Minimal setup via continuation |
| **Conforms to** | Itself | `AsyncSequence` |

In practice, prefer `AsyncStream` unless you need a reusable named type.

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

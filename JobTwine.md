# JobTwine Interview Questions

## How to convert Objective-C code so it uses async/await swift instead?

Objective-C APIs that use completion handlers can be bridged into Swift's async/await system in two ways.

**Automatic bridging** — If the Objective-C method follows Apple's naming conventions and uses `NS_SWIFT_ASYNC` annotations or a `completionHandler:` parameter, the Swift compiler may generate an `async` variant automatically. You simply call it with `await` and the compiler handles the bridge.

**Manual bridging with continuations** — When automatic bridging doesn't apply, you wrap the callback-based call inside `withCheckedContinuation` (for non-throwing methods) or `withCheckedThrowingContinuation` (for methods that can fail). Inside the closure you call the Objective-C method, and in its completion handler you call `continuation.resume(returning:)` on success or `continuation.resume(throwing:)` on failure. The `await` call then suspends until the completion handler fires.

**Key rules to follow:**
- You must call `resume` exactly once — calling it zero times hangs the task forever; calling it twice crashes.
- If the Objective-C completion block can return an error (an `NSError *` parameter), use the throwing variant so the error propagates naturally as a Swift `throw`.
- If the method delivers results on a background thread, you don't need to dispatch back to the main thread yourself — the caller controls that with `await` on the `@MainActor` or inside a `Task`.
- For streaming callbacks (called multiple times, like progress updates), continuations are not the right tool. Use `AsyncStream` instead, which lets you `yield` multiple values over time.


## How to call Objective-C code dynamically from Swift using a selector?

In Swift, you can call Objective-C methods dynamically using `perform(_:)` and related selector-based APIs. The target class must inherit from `NSObject` and the method must be marked with `@objc` to be visible to the Objective-C runtime. You reference the method using `#selector()`, which gives you compile-time safety — the compiler will error if the method doesn't exist. `perform(_:)` handles no-argument calls, while `perform(_:with:)` passes a single argument. The return value comes back as `Unmanaged<AnyObject>?`, so you need to call `.takeUnretainedValue()` to extract it if needed.


## How to integrate a GraphQL API with a SwiftUI view?

GraphQL requests are always HTTP POST calls with a JSON body containing a `"query"` string and optionally a `"variables"` dictionary. You can use plain `URLSession` with `async/await` without any third-party library — just set the method to POST, add the `Content-Type: application/json` header, encode the query into the body, and decode the JSON response.

For a richer, type-safe experience, **Apollo iOS** (added via Swift Package Manager) auto-generates Swift models from your `.graphql` schema files, so every query and response field is strongly typed.

In SwiftUI, the typical pattern is an `ObservableObject` view model with `@Published` properties for the data, loading state, and errors. The view binds to those properties and triggers the fetch using `.task {}`. On iOS 17+ you can use the `@Observable` macro instead of `ObservableObject`.


## How to mock URLSession using Combine?

The standard approach is **protocol-based dependency injection**. You define a `URLSessionProtocol` with a `dataTaskPublisher(for:)` method, then conform the real `URLSession` to it. In tests, you inject a `MockURLSession` that returns a hardcoded response instead of hitting the network.

For a successful response, the mock returns a `Just` publisher (which emits one value and completes) combined with `setFailureType(to: URLError.self)` to match the expected publisher type. For an error scenario, the mock returns a `Fail` publisher that immediately emits a `URLError`.

The service class takes a `URLSessionProtocol` in its initializer, defaulting to `URLSession.shared` in production. In tests you pass the mock. This pattern keeps production code unchanged while making it fully testable. An alternative approach — without a custom protocol — is to subclass `URLProtocol` and register it with the session configuration.


## How to snapshot test a SwiftUI view for both light and dark mode simultaneously?

**SnapshotTesting** by Point-Free is the standard library for this. It renders a view into an image and compares it against a stored reference image on disk. The first time a test runs it records the reference images into a `__Snapshots__` folder, which you commit to source control. Every subsequent run does a pixel-by-pixel comparison and fails if anything changed.

To test both appearances, you call `assertSnapshot` twice — once with a `UITraitCollection` set to `.light` and once set to `.dark` — giving each a distinct `named:` parameter so they are stored as separate reference images. Alternatively, `assertSnapshots` accepts a dictionary of named strategies so you can cover both modes in a single call.

Because SwiftUI views don't directly integrate with UIKit snapshot infrastructure, you wrap them in a `UIHostingController` first. When you intentionally update the UI, set `isRecording = true` on the test to regenerate the reference images, then remove that flag before committing.


## How do you identify and fix retain cycles in Swift?

A retain cycle occurs when two or more objects hold strong references to each other, preventing ARC from deallocating either one. The most common sources are closures capturing `self` strongly, and delegate patterns where the delegate property is declared `strong` instead of `weak`.

To identify them, you use the Memory Graph Debugger in Xcode (the three-circle icon in the debug bar). It shows a visual graph of all live objects and their reference paths. If an object you expected to be released is still alive and its reference chain loops back to itself, that's a cycle. Instruments' Leaks and Allocations templates can also catch retained objects over time.

To fix them, you capture `self` weakly in closures using `[weak self]` and guard against `nil` at the start of the closure. Use `[unowned self]` only when you are certain the closure will never outlive the object — if you're wrong, it crashes. For delegates, always declare the property as `weak var delegate: SomeProtocol?` — the protocol must be class-constrained (`AnyObject`) for this to work. For two objects that genuinely need to reference each other, one side should always be weak.


## What is the difference between Swift actors and serial DispatchQueues?

Both protect shared mutable state from data races by serializing access, but they work at different levels of the concurrency model.

A serial `DispatchQueue` is a GCD primitive — you protect state by dispatching work synchronously or asynchronously onto the queue, and you must manually ensure all access goes through it. There is no compiler enforcement, so it's easy to accidentally access the state from outside the queue. Blocking a thread with `sync` can also cause deadlocks or thread exhaustion.

An `actor` is a Swift language construct that gives you compile-time data race protection. The compiler enforces that any access to an actor's mutable properties from outside the actor must be `await`-ed. Actors use Swift's cooperative thread pool rather than dedicated threads, so they scale better and don't block underlying threads while waiting. The main difference in practice is that actors integrate naturally with `async/await` and give you safety guarantees at compile time, while queues are lower-level and rely on discipline to use correctly.

`@MainActor` is a global actor that replaces the common pattern of dispatching UI updates to `DispatchQueue.main` — annotating a class or function with `@MainActor` tells the compiler to always run it on the main thread, and violations are caught at compile time.


## How does the iOS rendering pipeline work and what causes dropped frames?

The GPU renders at 60fps (or 120fps on ProMotion displays), meaning each frame has roughly 16ms (or 8ms) to complete. The pipeline has two main phases: the CPU phase and the GPU phase.

In the CPU phase, Core Animation traverses the layer tree, computes layout, prepares drawing commands, and commits a transaction to the render server (a separate process called `backboardd`). In the GPU phase, the render server composites all the layers into the final frame using the GPU.

Dropped frames happen when either phase takes too long. Common CPU-side causes are performing expensive work on the main thread (network, disk I/O, heavy computation), complex Auto Layout constraint solving, and large `UITableView`/`UICollectionView` cell preparations that aren't deferred. Common GPU-side causes are offscreen rendering (triggered by `cornerRadius` with `masksToBounds`, shadows without an explicit `shadowPath`, and `shouldRasterize`), transparent overlapping layers (blending), and very large textures.

You diagnose this using Instruments' Core Animation template, which shows CPU and GPU usage per frame, and Xcode's Debug > Color Blended Layers / Offscreen-Rendered overlays which highlight problem areas directly in the simulator.


## How do you architect a large iOS app for testability and maintainability?

The goal is to separate concerns so that each layer can be tested in isolation and replaced without rippling changes through the codebase.

The most common approach is a layered architecture — typically **Presentation**, **Domain**, and **Data** layers. The Presentation layer contains views and view models with no business logic. The Domain layer contains use cases and models that are pure Swift with no UIKit or framework dependencies. The Data layer handles networking, persistence, and mapping external models to domain models.

Dependency injection ties these layers together. Rather than having objects create their own dependencies, they receive them through initializers or property injection. This makes it trivial to swap real implementations for mocks in tests. A dependency container (or a lightweight DI framework like Needle or Swinject) manages the wiring at the app's composition root.

For state management at scale, unidirectional data flow patterns like **TCA (The Composable Architecture)** enforce that state only changes through explicit actions, making the app fully predictable and every state transition unit-testable. For simpler apps, MVVM with Combine or `@Observable` is sufficient.

Protocol-based abstractions at layer boundaries are essential — the domain layer should depend on protocols for its data sources, never on concrete networking or database classes. This is the **Dependency Inversion Principle** and it's what makes the architecture actually testable.


## How does Core Data handle concurrency and what are the common pitfalls?

Core Data is not thread-safe. Every `NSManagedObjectContext` and the `NSManagedObject` instances it vends must be used only on the thread or queue they were created on. Accessing them from the wrong thread causes random crashes and data corruption.

The standard modern setup uses a **persistent container** with a `viewContext` for read-only UI work on the main thread, and `newBackgroundContext()` or `performBackgroundTask` for writes on a private background queue. Core Data automatically merges changes from background contexts into the `viewContext` when you set `automaticallyMergesChangesFromParent = true`.

Common pitfalls: passing `NSManagedObject` instances across threads instead of passing their `NSManagedObjectID` and re-fetching on the target context; forgetting to call `context.perform` or `context.performAndWait` when doing work on a background context; saving a child context without saving its parent (the changes never reach the persistent store); and performing fetches on the `viewContext` from background threads.

For large imports, doing everything in one context and one save is much faster than saving after every object — batching writes and using `NSBatchInsertRequest` (iOS 13+) can be orders of magnitude faster because it bypasses the change tracking overhead of individual `NSManagedObject` instances.


## How do you handle deep linking and universal links in an iOS app?

Deep links let external URLs or push notifications navigate the user to a specific screen inside the app. There are two mechanisms: **URL schemes** (custom `myapp://` URLs) and **Universal Links** (standard `https://` URLs via the Associated Domains entitlement).

Universal Links are preferred because they fall back gracefully to the website in a browser if the app isn't installed, and they can't be hijacked by another app registering the same scheme. They require hosting an `apple-app-site-association` (AASA) JSON file at the root of your domain and adding the `applinks:` entry to the app's Associated Domains capability.

On the architecture side, the app needs a central router or coordinator that parses the incoming URL, extracts parameters, and navigates the view hierarchy to the correct screen. The router is called from `scene(_:continue:)` for Universal Links and `scene(_:openURLContexts:)` for URL schemes in the scene delegate. The challenge in complex apps is handling deep links that arrive before the UI is fully set up (e.g., on cold launch) — the standard solution is to store the pending link and process it once the root view controller is ready.

For testing, the `xcrun simctl openurl booted "myapp://path"` command opens a URL in the simulator without needing a real device.


## What strategies do you use to reduce app launch time?

Launch time is split into **pre-main** (everything before `main()` runs, controlled by the OS and dynamic linker) and **post-main** (your `AppDelegate`/`SceneDelegate` setup and the first frame render).

To reduce pre-main time: minimize the number of dynamic frameworks (each one adds dylib loading overhead), avoid `+load` methods in Objective-C (they run at link time before `main`), and prefer `+initialize` or lazy initialization. Swift's initializers are generally fine since they run on demand.

To reduce post-main time: defer everything non-essential. Don't set up analytics SDKs, register for remote notifications, or initialize third-party libraries synchronously in `application(_:didFinishLaunchingWithOptions:)`. Use `DispatchQueue.main.async` or `Task { }` to push non-critical setup to after the first frame. Avoid synchronous disk reads or network calls at launch. Pre-warm caches lazily.

Measure with Instruments' App Launch template, which gives a timeline from process start to first frame with flame graphs for every method called. The `DYLD_PRINT_STATISTICS` environment variable in the scheme's launch arguments also prints a breakdown of pre-main phases directly in the Xcode console.

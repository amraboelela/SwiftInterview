# JobTwine Interview Questions

## Add extension to UIImageView to allow image caching

The standard approach is to use `NSCache` as the backing store — it behaves like a dictionary but automatically evicts entries under memory pressure, which makes it ideal for image caching. You store the cache as a static property on the extension so it is shared across all `UIImageView` instances.

The extension adds a method that takes a URL, checks the cache first using the URL string as the key, and returns the cached image immediately if it exists. On a cache miss, it downloads the image data asynchronously using `URLSession`, decodes it into a `UIImage`, stores it in the cache, and then dispatches back to the main thread to set `self.image`. You must always dispatch the image assignment to the main thread because `URLSession` completion handlers run on a background thread and UIKit is not thread-safe.

A subtle but important detail is the stale-load problem: in a `UITableView` or `UICollectionView`, a cell can be requeued and assigned a new URL before the previous download finishes. When the old download completes it will overwrite the new image. The fix is to tag the image view with the requested URL before starting the download, then check inside the completion handler that the image view's current URL still matches — if it doesn't, you discard the result.

For production use, `SDWebImage` or `Kingfisher` are the standard third-party libraries. They handle all of the above plus disk caching (so images survive app restarts), progressive loading, image transformations, and cancellation. The extension approach is appropriate when you want zero dependencies or are demonstrating the underlying concept in an interview.

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

## How do you handle deep linking and universal links in an iOS app?

Deep links let external URLs or push notifications navigate the user to a specific screen inside the app. There are two mechanisms: **URL schemes** (custom `myapp://` URLs) and **Universal Links** (standard `https://` URLs via the Associated Domains entitlement).

Universal Links are preferred because they fall back gracefully to the website in a browser if the app isn't installed, and they can't be hijacked by another app registering the same scheme. They require hosting an `apple-app-site-association` (AASA) JSON file at the root of your domain and adding the `applinks:` entry to the app's Associated Domains capability.

On the architecture side, the app needs a central router or coordinator that parses the incoming URL, extracts parameters, and navigates the view hierarchy to the correct screen. The router is called from `scene(_:continue:)` for Universal Links and `scene(_:openURLContexts:)` for URL schemes in the scene delegate. The challenge in complex apps is handling deep links that arrive before the UI is fully set up (e.g., on cold launch) — the standard solution is to store the pending link and process it once the root view controller is ready.

For testing, the `xcrun simctl openurl booted "myapp://path"` command opens a URL in the simulator without needing a real device.


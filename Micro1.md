# Micro1 Interview Questions

Interviewer: Zara — iOS

## Q: How does SwiftUI compare to UIKit in terms of performance?

**Answer:**

SwiftUI and UIKit have different performance characteristics. UIKit is the older, more mature framework with predictable performance — you have direct, imperative control over the view hierarchy, and rendering cost is straightforward to reason about. SwiftUI is declarative: the framework diffs the view tree on every state change and decides what to update.

**Where SwiftUI is faster or comparable:**

- Simple to medium-complexity screens — the diffing engine is highly optimized, and SwiftUI uses lighter-weight value types (structs) for views instead of `UIView` subclasses
- `LazyVStack`, `LazyHStack`, and `List` only instantiate cells as they appear, similar to `UITableView`/`UICollectionView` but with less boilerplate
- Animations are GPU-accelerated by default and run on the render server

**Where UIKit still wins:**

- Very large, deeply nested view hierarchies — SwiftUI's diffing cost grows with the size of the body
- Highly custom drawing or per-pixel control — `UIView`'s `draw(_:)` and `CALayer` give you direct Core Graphics access
- Complex collection views with custom layouts — `UICollectionViewCompositionalLayout` is more flexible than `LazyVGrid` for advanced cases
- Older iOS versions — SwiftUI requires iOS 13+, and many features need iOS 15/16/17

**Common SwiftUI performance pitfalls:**

- Putting expensive work directly inside `body` — `body` can be called many times per second, so any computation there runs every time
- Overusing `@StateObject` / `@ObservedObject` at high levels — a single `@Published` change re-evaluates the whole subtree
- Not using `Equatable` views or `.equatable()` to short-circuit diffing on unchanged data
- Using `AnyView` excessively — it erases type information and forces SwiftUI to rebuild instead of diff

In practice, modern apps mix both: SwiftUI for most screens, UIKit (via `UIViewRepresentable`) for the few cases where you need fine-grained control.


## Q: How do you make networking calls using URLSession?

**Answer:**

`URLSession` is Apple's built-in HTTP client. The modern approach uses `async/await`, which replaces the older completion-handler and Combine APIs.

**Basic GET request:**

```swift
struct User: Decodable {
    let id: Int
    let name: String
}

func fetchUser(id: Int) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(User.self, from: data)
}
```

**POST request with a JSON body:**

```swift
func createUser(_ user: User) async throws -> User {
    let url = URL(string: "https://api.example.com/users")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(user)

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(User.self, from: data)
}
```

**Key points:**

- Always validate the `HTTPURLResponse` status code — `URLSession` only throws on transport errors, not HTTP errors like 404 or 500
- Use a custom `URLSessionConfiguration` for things like timeout, caching policy, or HTTP headers shared across requests
- For large downloads/uploads use `URLSession.download(for:)` and `URLSession.upload(for:from:)` which write to disk and stream
- For authentication, set the `Authorization` header on the request, or implement `URLSessionDelegate` for challenge handling
- Cancel in-flight requests by storing the `Task` and calling `task.cancel()` — `URLSession` honors task cancellation

**Older completion-handler style (still valid):**

```swift
URLSession.shared.dataTask(with: url) { data, response, error in
    // runs on a background thread
}.resume()
```

This is what you bridge with `withCheckedThrowingContinuation` if you need to wrap a legacy API into `async/await`.


## Q: How do you measure performance in an iOS app?

**Answer:**

There are several layers of performance measurement, from quick in-code timing to full Instruments profiling.

### 1. Quick timing with `CFAbsoluteTimeGetCurrent` or `Date`

```swift
let start = CFAbsoluteTimeGetCurrent()
expensiveWork()
let elapsed = CFAbsoluteTimeGetCurrent() - start
print("Took \(elapsed) seconds")
```

Useful for ad-hoc measurement during development. Not precise enough for sub-millisecond work.

### 2. `ContinuousClock` (Swift 5.7+)

```swift
let clock = ContinuousClock()
let elapsed = clock.measure {
    expensiveWork()
}
print(elapsed)  // prints a Duration
```

Cleaner, modern API. Use this in new code.

### 3. `os_signpost` — for production-friendly tracing

```swift
import os.signpost

let log = OSLog(subsystem: "com.example.app", category: .pointsOfInterest)
let id = OSSignpostID(log: log)

os_signpost(.begin, log: log, name: "Load Feed", signpostID: id)
loadFeed()
os_signpost(.end, log: log, name: "Load Feed", signpostID: id)
```

These signposts show up as bands in Instruments' **Points of Interest** track, so you can correlate them with CPU, memory, and rendering data.

### 4. XCTest performance tests

```swift
func testFeedDecodingPerformance() {
    measure {
        _ = try? JSONDecoder().decode([Post].self, from: largeJSONData)
    }
}
```

Xcode runs the block 10 times, computes the mean and standard deviation, and lets you set a baseline. CI can fail the test if performance regresses.

You can also use `measure(metrics:)` to capture specific metrics like `XCTClockMetric`, `XCTCPUMetric`, `XCTMemoryMetric`, or `XCTApplicationLaunchMetric`.

### 5. Instruments — the real tool

Profile via **Product > Profile** (`Cmd + I`):

- **Time Profiler** — samples the call stack, shows where CPU time is spent
- **Allocations** — tracks memory allocations and live objects, useful for finding bloat
- **Leaks** — detects retain cycles and unreleased memory
- **Network** — inspects every URLSession request/response and timing
- **SwiftUI** (Xcode 15+) — shows view body invocations, helps find views that re-render too often
- **Hangs** and **Time Profiler** together — diagnose main-thread stalls
- **Animation Hitches** — shows frames that missed the 60/120 Hz target

### 6. MetricKit — production telemetry

`MetricKit` delivers daily reports from real users on launch time, hangs, disk usage, battery impact, and crashes:

```swift
import MetricKit

class MetricsObserver: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        // upload to your analytics backend
    }
}
```

Pair this with crash reporting (Sentry, Crashlytics) for a full production view.

### 7. Xcode Organizer

For shipped apps, **Window > Organizer > Metrics** shows aggregated launch time, hangs, scrolling hitches, battery, and memory across real users — broken down by device and OS version. No code required, just App Store distribution.


## Q: How do you reduce network latency in an iOS app?

**Answer:**

- **HTTP caching** — set `URLCache` and respect `Cache-Control` headers from the server. `URLSessionConfiguration.default` already has a caching policy of `.useProtocolCachePolicy`
- **Compression** — request `Accept-Encoding: gzip` (URLSession does this automatically) and ensure the server gzips responses
- **HTTP/2 and HTTP/3** — `URLSession` uses HTTP/2 automatically when the server supports it, allowing multiplexed requests on a single connection
- **Connection reuse** — share a single `URLSession` instance across the app instead of creating new ones
- **Prefetching** — anticipate the next screen and start the request early, store the result in memory
- **Pagination** — request small pages instead of huge payloads, fetch the next page as the user scrolls
- **CDN** — serve static assets and images from a CDN closer to the user
- **Image downsampling** — decode images at the display size, not the full resolution, using `ImageIO` or `CGImageSourceCreateThumbnailAtIndex`
- **Background URLSession** — for non-urgent uploads/downloads, use a background session so the system schedules them efficiently


## Q: How do you handle slow scrolling in a UICollectionView or List?

**Answer:**

Slow scrolling almost always comes down to the main thread doing too much work per frame. The 60 Hz target gives you ~16 ms per frame; on ProMotion 120 Hz devices it's ~8 ms.

**Common causes and fixes:**

- **Image decoding on the main thread** — decode in the background using `ImageIO` and assign on main; cache the decoded `UIImage`
- **Synchronous network calls** — never block the main thread; use `async/await` and show placeholders
- **Auto Layout on complex cells** — measure with the Time Profiler; consider manual layout or `UICollectionViewCompositionalLayout` with cached sizes
- **Off-screen rendering** — avoid `cornerRadius` + `masksToBounds` on layers with shadows; use pre-rendered images or `cornerCurve = .continuous`
- **Cell reuse missing** — ensure `dequeueReusableCell` is used; in SwiftUI `List` and `LazyVStack` already reuse internally
- **Heavy work in `cellForItemAt`** — keep this method tight; do data transformation in the view model, not the cell

Use Instruments' **Animation Hitches** template to find dropped frames, then drill in with Time Profiler.


## Q: What's the difference between `URLSession.shared` and a custom session?

**Answer:**

`URLSession.shared` is a singleton with default configuration — fine for simple, occasional requests. It uses the global cache, cookies, and credential store, and you can't configure things like timeout, custom headers, or delegate callbacks.

A custom `URLSession` is created with a `URLSessionConfiguration`:

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
config.httpAdditionalHeaders = ["X-API-Key": apiKey]
config.requestCachePolicy = .reloadIgnoringLocalCacheData
config.waitsForConnectivity = true

let session = URLSession(configuration: config)
```

Three configuration types:

- `.default` — disk-cached, persistent cookies, credentials
- `.ephemeral` — in-memory only, nothing persists between launches (good for private browsing)
- `.background(withIdentifier:)` — system schedules the transfer; survives app suspension and termination

Use a custom session whenever you need shared headers, custom timeout, a delegate (for auth challenges, redirects, or progress), or background transfers. Hold a single instance per logical service rather than creating new sessions per request — sessions are expensive to set up and reuse connections internally.

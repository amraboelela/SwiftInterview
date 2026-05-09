# Micro1 Interview Questions

Interviewer: Zara — iOS

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

### 3. XCTest performance tests

```swift
func testFeedDecodingPerformance() {
    measure {
        _ = try? JSONDecoder().decode([Post].self, from: largeJSONData)
    }
}
```

Xcode runs the block 10 times, computes the mean and standard deviation, and lets you set a baseline. CI can fail the test if performance regresses.

You can also use `measure(metrics:)` to capture specific metrics like `XCTClockMetric`, `XCTCPUMetric`, `XCTMemoryMetric`, or `XCTApplicationLaunchMetric`.

### 4. Instruments — the real tool

Profile via **Product > Profile** (`Cmd + I`):

- **Time Profiler** — samples the call stack, shows where CPU time is spent
- **Allocations** — tracks memory allocations and live objects, useful for finding bloat
- **Leaks** — detects retain cycles and unreleased memory
- **Network** — inspects every URLSession request/response and timing
- **SwiftUI** (Xcode 15+) — shows view body invocations, helps find views that re-render too often
- **Hangs** and **Time Profiler** together — diagnose main-thread stalls
- **Animation Hitches** — shows frames that missed the 60/120 Hz target

### 5. Xcode Organizer

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


## Q: How do you structure shared state in an iOS app — what does a proper model layer look like?

**Answer:**

A clean iOS app keeps state out of the view layer. Views render state and forward intents; they don't own truth. The pattern that scales is a dedicated model layer — usually one or more reference-type stores (often actors or `@MainActor` classes) that hold the canonical data and publish changes.

**Typical layout:**

```swift
// 1. Pure data — value types, Codable, Equatable
struct Post: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let body: String
}

// 2. Repository / service — owns I/O and caching, no UI knowledge
protocol PostRepository {
    func fetchAll() async throws -> [Post]
    func save(_ post: Post) async throws
}

// 3. Store — the single source of truth for a feature, observable by views
@MainActor
final class FeedStore: ObservableObject {
    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let repository: PostRepository

    init(repository: PostRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            posts = try await repository.fetchAll()
        } catch {
            self.error = error
        }
    }
}

// 4. View — observes the store, renders, dispatches intents
struct FeedView: View {
    @StateObject var store: FeedStore

    var body: some View {
        List(store.posts) { Text($0.title) }
            .task { await store.load() }
    }
}
```

**Why this layering matters:**

- The `Post` value type is safe to pass anywhere — no shared mutable state surprises

- The repository hides whether data comes from network, disk, or memory — swap it for tests with a mock conforming to the protocol

- The store is the only thing that mutates state — UI reads `@Published` properties and calls intents (`load`, `save`)

- Dependencies flow inward (View → Store → Repository), never the other way

**For app-wide state** (current user, auth token, theme), use a single shared store injected through `.environmentObject(_:)` (SwiftUI) or a dependency container. Avoid singletons for anything testable — they're impossible to stub.

**Common anti-patterns to avoid:**

- Putting `URLSession` calls directly inside a SwiftUI view's `.task { }`

- Storing model data in `@State` (it's view-local and dies with the view)

- Reaching into a singleton from inside a view body — couples the view to the global graph and breaks previews

- Using `NotificationCenter` to broadcast state changes between unrelated parts of the app — prefer explicit `@Published` properties or a shared store


## Q: How should NotificationCenter observers be managed across a view's lifecycle?

**Answer:**

`NotificationCenter` is easy to misuse. The two failure modes are **leaks** (observer outlives its owner and keeps it alive) and **zombies** (observer fires after its owner is deallocated, crashing or reading freed state). The fix is to scope observation to the owner's lifetime.

**Modern Swift — block-based with explicit token:**

```swift
final class FeedViewController: UIViewController {
    private var tokens: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let token = NotificationCenter.default.addObserver(
            forName: .userDidLogin,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.refresh()
        }
        tokens.append(token)
    }

    deinit {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
```

**Key rules:**

- Always capture `[weak self]` in the block — otherwise the closure retains `self`, the observer retains the closure, and the view controller leaks until the notification fires (which may be never)

- Store the returned token and remove it explicitly on `deinit` — block-based observers do **not** get cleaned up automatically when the observer object is released; only the older `addObserver(_:selector:name:object:)` does

- Prefer specifying an `object:` filter when you only care about a specific sender — reduces noise and bug surface

- Pick a queue intentionally — `.main` for UI updates, `nil` for "deliver on the posting thread"

**Async/await alternative — `notifications(named:)`:**

```swift
final class FeedStore {
    private var observationTask: Task<Void, Never>?

    func startObserving() {
        observationTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .userDidLogin) {
                await self?.refresh()
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }
}
```

The `for await` loop ends automatically when the task is cancelled, so structured concurrency handles teardown for you.

**SwiftUI:**

```swift
struct FeedView: View {
    @StateObject var store = FeedStore()

    var body: some View {
        List(store.posts) { Text($0.title) }
            .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
                Task { await store.refresh() }
            }
    }
}
```

`onReceive` automatically subscribes when the view appears and cancels when it disappears — no manual token management.

**When NOT to use NotificationCenter:**

- Communicating between two specific objects you control — use a closure, delegate, or `@Published` property instead

- Broadcasting state changes inside your own app — a shared store is more testable and type-safe

- Reserve `NotificationCenter` for system events (`UIApplication.didBecomeActiveNotification`, keyboard show/hide, `NSManagedObjectContextDidSave`) and truly cross-cutting events where decoupling outweighs the loss of type safety


## Q: How do you safely cancel async tasks in Swift?

**Answer:**

Task cancellation in Swift is **cooperative** — calling `task.cancel()` doesn't stop execution; it sets a flag. The task must check that flag and bail out. Done right, cancellation is fast and leak-free; done wrong, you get wasted work, stale UI updates, and "ghost" requests that overwrite newer ones.

**The three cancellation primitives:**

```swift
// 1. Throw if cancelled
try Task.checkCancellation()

// 2. Read the flag without throwing
if Task.isCancelled { return }

// 3. Suspend and let cancellation propagate
try await Task.sleep(for: .seconds(1))
```

`URLSession.data(for:)`, `Task.sleep`, and most async APIs in the standard library check cancellation at every suspension point and throw `CancellationError` (or `URLError(.cancelled)`).

**Pattern 1 — search-as-you-type, cancel the previous in-flight task:**

```swift
@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var results: [Result] = []
    private var searchTask: Task<Void, Never>?

    func search(_ query: String) {
        searchTask?.cancel()                       // cancel the previous one
        searchTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))   // debounce
                try Task.checkCancellation()
                let fetched = try await api.search(query)
                try Task.checkCancellation()                    // don't publish stale results
                self.results = fetched
            } catch is CancellationError {
                // expected — ignore
            } catch {
                // handle real failures
            }
        }
    }
}
```

The two `checkCancellation()` calls are deliberate: one before the network call (skip it if the user already typed more), one after (don't overwrite newer results with older ones).

**Pattern 2 — cancel on view disappear (SwiftUI):**

```swift
struct FeedView: View {
    @StateObject var store = FeedStore()

    var body: some View {
        List(store.posts) { Text($0.title) }
            .task {                              // automatically cancelled when view disappears
                await store.load()
            }
    }
}
```

`.task` ties the lifetime of the work to the view's lifetime. No manual bookkeeping.

**Pattern 3 — cancel a long loop yourself:**

```swift
func processItems(_ items: [Item]) async throws {
    for item in items {
        try Task.checkCancellation()             // bail at every iteration
        try await process(item)
    }
}
```

**Pattern 4 — structured concurrency with `withTaskCancellationHandler`:**

```swift
func longRunning() async throws -> Data {
    try await withTaskCancellationHandler {
        try await downloadAndDecode()
    } onCancel: {
        // synchronous cleanup — close file, abort URLSessionTask, etc.
    }
}
```

The `onCancel` closure runs synchronously when cancellation is requested, even if the main work is still suspended. Use it for cleanup that can't go through `async` (file handles, C APIs, `URLSessionTask.cancel()`).

**Common mistakes:**

- Forgetting to check after the await — the network completes, you assign `self.results`, but the user already navigated away (silent stale write, or worse, a crash if the screen tore down state)

- Catching `Error` and treating `CancellationError` like a real failure — it isn't; just return

- Holding a `Task` reference but never cancelling it on `deinit` — the closure keeps `self` alive

- Calling `task.cancel()` and assuming it's done — the task continues running until it hits a checkpoint


## Q: How do you build a reusable, type-safe networking layer in Swift?

**Answer:**

A good networking layer hides URLs, HTTP verbs, encoding, and decoding behind a single function call per endpoint, while letting the compiler enforce request and response types. The pattern has three parts: an `Endpoint` describing a request, a generic `APIClient` that executes any endpoint, and per-feature endpoint definitions.

**Step 1 — describe an endpoint as data:**

```swift
struct Endpoint<Response: Decodable> {
    enum Method: String { case get = "GET", post = "POST", put = "PUT", delete = "DELETE" }

    let method: Method
    let path: String
    let query: [URLQueryItem]
    let body: Data?
    let headers: [String: String]

    init(
        method: Method = .get,
        path: String,
        query: [URLQueryItem] = [],
        body: Data? = nil,
        headers: [String: String] = [:]
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.headers = headers
    }
}
```

The generic `Response` parameter ties the endpoint to its return type — the compiler knows `usersEndpoint` returns `[User]` and refuses to decode it as anything else.

**Step 2 — one client that executes any endpoint:**

```swift
struct APIError: Error {
    let statusCode: Int
    let data: Data
}

actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private var defaultHeaders: [String: String] = [:]

    init(baseURL: URL, session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func setAuthToken(_ token: String?) {
        if let token {
            defaultHeaders["Authorization"] = "Bearer \(token)"
        } else {
            defaultHeaders.removeValue(forKey: "Authorization")
        }
    }

    func send<Response>(_ endpoint: Endpoint<Response>) async throws -> Response {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)!
        if !endpoint.query.isEmpty { components.queryItems = endpoint.query }

        var request = URLRequest(url: components.url!)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        for (k, v) in defaultHeaders { request.setValue(v, forHTTPHeaderField: k) }
        for (k, v) in endpoint.headers { request.setValue(v, forHTTPHeaderField: k) }

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw APIError(statusCode: code, data: data)
        }

        return try decoder.decode(Response.self, from: data)
    }
}
```

**Step 3 — declare endpoints per feature, in one place:**

```swift
extension Endpoint where Response == [User] {
    static func listUsers(page: Int = 1) -> Endpoint {
        Endpoint(path: "/users", query: [URLQueryItem(name: "page", value: "\(page)")])
    }
}

extension Endpoint where Response == User {
    static func createUser(_ body: NewUser) throws -> Endpoint {
        Endpoint(
            method: .post,
            path: "/users",
            body: try JSONEncoder().encode(body),
            headers: ["Content-Type": "application/json"]
        )
    }
}
```

**Call sites become trivial:**

```swift
let client = APIClient(baseURL: URL(string: "https://api.example.com")!)

let users = try await client.send(.listUsers(page: 2))      // [User] — inferred
let created = try await client.send(.createUser(newUser))   // User — inferred
```

**What this design buys you:**

- **Type safety** — wrong response type is a compile error, not a runtime decode crash

- **Testability** — inject a fake `URLSession` (via `URLProtocol`) or a mock `APIClient` conforming to a protocol; no real network in tests

- **Single chokepoint** — auth token, base URL, decoder config, error mapping, and cancellation checks live in one place

- **Composability** — wrap `send` for retries, logging, or circuit breaking without touching call sites

- **Cancellation propagation** — `URLSession` honors task cancellation and `Task.checkCancellation()` after the await prevents stale writes

For larger apps, layer a feature-level repository on top (`UserRepository`, `FeedRepository`) so the rest of the code never imports `APIClient` directly — it only sees domain methods.


## Q: How do you solve the "minimum group tickets" problem efficiently — and what's the standard greedy approach?

**Answer:**

**Problem:** Given an array of ages (each `1...120`) and a `maxDiff` (e.g. 5), return the minimum number of groups needed so that within each group, `maxAge - minAge <= maxDiff`.

**Standard greedy approach:**

1. Sort the ages ascending (or use counting sort — see below for the optimization)

2. Walk the sorted ages. Anchor a new group at the smallest unassigned age. Keep extending the group while the next age is within `maxDiff` of the anchor. When it isn't, start a new group anchored there

3. Return the number of anchors opened

**Why greedy works:** Walking ages ascending, the smallest unassigned age MUST be the minimum of its group. Stretching the group as far right as `maxDiff` allows can only reduce or equal the number of groups compared to closing earlier — so the local choice is also globally optimal. This is a textbook **interval-cover** greedy proof.

**O(n log n) sort + sweep:**

```swift
func minGroupTickets(ages: [Int], maxDiff: Int) -> Int {
    guard !ages.isEmpty else { return 0 }

    let sorted = ages.sorted()
    var groups = 1
    var anchor = sorted[0]

    for age in sorted.dropFirst() {
        if age - anchor > maxDiff {
            groups += 1
            anchor = age
        }
    }
    return groups
}
```

**O(n + k) counting sort — beats O(n log n) when values are bounded:**

Because ages are bounded to `1...120`, we can skip the comparison sort entirely:

```swift
func minGroupTickets(ages: [Int], maxDiff: Int) -> Int {
    guard !ages.isEmpty else { return 0 }

    var counts = [Int](repeating: 0, count: 121)
    for age in ages { counts[age] += 1 }

    var groups = 0
    var anchor = -1
    for age in 1...120 where counts[age] > 0 {
        if anchor < 0 || age - anchor > maxDiff {
            groups += 1
            anchor = age
        }
    }
    return groups
}
```

This is **O(n + k)** where `k = 120` — effectively O(n). On a 100k-age stress test, this version runs in ~15 ms versus ~500 ms for the sort-based set approach (about 33× faster).

**Edge cases to handle:**

- **Empty input** → return 0, not 1

- **Single age** → return 1

- **All same age** → 1 group regardless of `maxDiff`

- **`maxDiff == 0`** → each distinct age becomes its own group

- **`maxDiff` larger than the value range** → 1 group (everyone fits)

- **Unsorted input** → must sort first (or counting-bucket) for correctness

**Common wrong approaches and why they fail:**

- **`Set<Int>` of "anchors" with a symmetric ±`maxDiff` window check** — over-merges. With `[5, 10, 1]` and `maxDiff=5`: 5 → {5}; 10 matches 5; 1 matches 5; returns 1, but `10 - 1 = 9 > 5` so the correct answer is 2. The set never records that the group's max grew to 10

- **Same set approach but "replacing the anchor with a smaller new age"** — still wrong for the same reason: the set tracks one number per group, but a group is defined by its **interval** `[min, max]`. Shrinking the recorded anchor doesn't undo the group's already-extended max

- **Both bugs disappear if you sort first** — once ages arrive ascending, the first age in a group IS its min and STAYS its min, so the single stored anchor is faithful

**Takeaway for interviews:** when a problem has bounded values (`age 1...120`, lowercase letters, byte values), counting sort beats comparison sort. State the greedy invariant out loud — "the smallest unassigned element must be the min of its group" — before coding. Then walk through the edge case list before declaring the solution done.

# XCUI (XCUITest) Interview Questions & Answers

**Q: What is XCUITest and how does it differ from XCTest?**

A: XCTest is Apple's unit and integration testing framework. XCUITest (UI Testing) is built on top of XCTest and enables automated UI testing by simulating user interactions with the app's interface. XCTest runs in the same process as the app, while XCUITest runs in a separate process and communicates with the app via the accessibility framework.

---

**Q: What are the main classes used in XCUITest?**

A:
- `XCUIApplication` — represents the app under test; used to launch, terminate, and query the app
- `XCUIElement` — represents a UI element (button, label, text field, etc.)
- `XCUIElementQuery` — a query that resolves to a collection of elements
- `XCTestCase` — the base class for all test cases, including UI tests
- `XCUIDevice` — provides access to device-level interactions (rotation, home button, etc.)

---

**Q: How do you structure a UI test file?**

A:
```swift
import XCTest

final class LoginUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testSuccessfulLogin() throws {
        app.textFields["emailField"].tap()
        app.textFields["emailField"].typeText("user@example.com")
        app.secureTextFields["passwordField"].tap()
        app.secureTextFields["passwordField"].typeText("password123")
        app.buttons["loginButton"].tap()
        XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 5))
    }
}
```

---

**Q: How do you launch an app in a UI test?**

A:
```swift
let app = XCUIApplication()
app.launch()
```

You can also pass launch arguments or environment variables:
```swift
app.launchArguments = ["--uitesting"]
app.launchEnvironment = ["DISABLE_ANIMATIONS": "1"]
app.launch()
```

---

**Q: What is the benefit of `launchArguments` and `launchEnvironment`?**

A:

**`launchArguments = ["--uitesting"]`** — passes string flags to the app at launch. Your app detects them via `ProcessInfo.processInfo.arguments` and changes behavior specifically for testing:

```swift
// In app code
if ProcessInfo.processInfo.arguments.contains("--uitesting") {
    // Skip onboarding
    // Use mock data instead of real API
    // Reset app state to a clean slate
}
```

Note: `CommandLine.arguments` is an equivalent Swift stdlib alternative, but using `ProcessInfo` for both arguments and environment keeps everything consistent in one place.

The benefit is **test isolation** — every test starts from a known, predictable state without depending on previous runs or real backend data.

**`launchEnvironment = ["DISABLE_ANIMATIONS": "1"]`** — passes key-value pairs read via `ProcessInfo`:

```swift
// In app code
if ProcessInfo.processInfo.environment["DISABLE_ANIMATIONS"] == "1" {
    UIView.setAnimationsEnabled(false)
}
```

The benefit is **speed and reliability** — animations cause tests to fail because XCUITest tries to interact with elements while they're still mid-animation. Disabling them makes tests 2–3x faster and eliminates flaky failures.

| | `launchArguments` | `launchEnvironment` |
|---|---|---|
| Type | Array of strings | Dictionary of strings |
| Read via | `ProcessInfo.processInfo.arguments` | `ProcessInfo.processInfo.environment` |
| Best for | Feature flags / modes | Configuration values |
| Example | `"--uitesting"`, `"--reset"` | `"DISABLE_ANIMATIONS": "1"`, `"BASE_URL": "mock"` |

Both are only injected during testing — they have no effect on App Store builds.

---

**Q: Why use `setUpWithError() throws` instead of `setUp()`?**

A: `setUpWithError()` lets you throw errors — if something in setup fails, the test fails immediately with a clear error message instead of silently continuing with broken state.

```swift
// Legacy — can't throw, failures are silent or cause crashes
override func setUp() {
    super.setUp()
}

// Modern — can throw, test fails immediately with a clear message
override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
}
```

| | `setUp()` | `setUpWithError()` |
|---|---|---|
| Can throw | No | Yes |
| Introduced | Original XCTest | Xcode 11 |
| Recommended | Legacy | Yes (modern default) |

Xcode generates `setUpWithError()` by default in new test files — use it consistently even if you don't throw today, it's future-proof.

---

**Q: What does `continueAfterFailure = false` do?**

A: When set to `false`, the test stops immediately after the first assertion failure. This prevents cascading failures where subsequent steps fail only because an earlier step failed, making it easier to diagnose the root cause. It is recommended to set this in `setUp` for UI tests.

---

**Q: How do you find and interact with UI elements?**

A:
```swift
let app = XCUIApplication()

// Tap a button by accessibility identifier
app.buttons["loginButton"].tap()

// Type into a text field
let emailField = app.textFields["emailField"]
emailField.tap()
emailField.typeText("user@example.com")

// Assert a label exists
XCTAssertTrue(app.staticTexts["Welcome"].exists)
```

---

**Q: What is the difference between `XCUIElementQuery` and `XCUIElement`?**

A: `XCUIElementQuery` does **not** have a `.tap()` method — only `XCUIElement` does. You must first resolve a query to an element before interacting with it:

```swift
app.buttons              // XCUIElementQuery — "all buttons", no .tap()
app.buttons["login"]     // XCUIElement — subscript resolves the query, has .tap()
app.buttons.firstMatch   // XCUIElement — resolved via .firstMatch, has .tap()
app.buttons.element      // XCUIElement — resolved via .element, has .tap()

app.buttons["login"].tap()    // ✅
app.buttons.firstMatch.tap()  // ✅
app.buttons.element.tap()     // ✅
```

| Expression | Type | Has `.tap()`? |
|---|---|---|
| `app.buttons` | `XCUIElementQuery` | No |
| `app.buttons["x"]` | `XCUIElement` | Yes |
| `app.buttons.firstMatch` | `XCUIElement` | Yes |
| `app.buttons.element` | `XCUIElement` | Yes |

The query describes *what to find*; the element is *what you found*. The rule is: **query → resolve → interact**.

`app.buttons["login"]` always returns a valid `XCUIElement` object, never `nil`. If the element doesn't exist in the UI, it returns a phantom element with `exists == false`. Calling `.tap()` on it fails the test; checking `.exists` is always safe:

```swift
let button = app.buttons["login"]  // always returns XCUIElement, never nil
button.exists                      // false if not found in UI
button.tap()                       // fails the test because exists == false

if button.exists {
    button.tap()                   // safe
}
```

---

**Q: What happens if you call `.tap()` on an element that doesn't exist?**

A: The test **fails** (not crashes) with "Failed to find matching element". Use `waitForExistence` or `.exists` to handle it safely:

```swift
// ❌ Fails the test if element is missing
app.buttons["loginButton"].tap()

// ✅ Wait for it to appear
let button = app.buttons["loginButton"]
XCTAssertTrue(button.waitForExistence(timeout: 5))
button.tap()  // or .click() on macOS

// ✅ Conditional interaction
if button.exists {
    button.tap()  // or .click() on macOS
}
```

| Code | Element missing behavior |
|------|--------------------------|
| `app.buttons["x"]` | Returns phantom XCUIElement, exists == false |
| `.exists` | Returns `false` — safe |
| `.tap()` / `.click()` | Fails the test immediately |
| `.waitForExistence(timeout:)` | Returns `false` after timeout — safe |

---

**Q: How do you wait for an element to appear?**

A:
```swift
let button = app.buttons["submitButton"]
let exists = button.waitForExistence(timeout: 5)
XCTAssertTrue(exists, "Submit button did not appear in time")
```

---

**Q: What is the Swift Testing equivalent of `waitForExistence(timeout:)`?**

A: Swift Testing has no built-in equivalent — you poll manually with `Task.sleep`:

```swift
// XCTest
XCTAssertTrue(button.waitForExistence(timeout: 5))

// Swift Testing — poll until element exists
@Test func buttonAppears() async throws {
    let button = app.buttons["submitButton"]
    let deadline = Date.now.addingTimeInterval(5)
    while !button.exists && Date.now < deadline {
        try await Task.sleep(for: .seconds(0.1))
    }
    #expect(button.exists)
}
```

Or wrap it in a reusable helper:
```swift
func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 5) async throws {
    let deadline = Date.now.addingTimeInterval(timeout)
    while !element.exists && Date.now < deadline {
        try await Task.sleep(for: .seconds(0.1))
    }
}

@Test func buttonAppears() async throws {
    let button = app.buttons["submitButton"]
    try await waitForExistence(button)
    #expect(button.exists)
}
```

| | XCTest | Swift Testing |
|---|---|---|
| Wait API | `waitForExistence(timeout:)` | No built-in — poll manually |
| Assert | `XCTAssertTrue` | `#expect` |
| Async | No | Yes (`async throws`) |
| Test annotation | `func test...()` | `@Test func ...()` |

Swift Testing still has no built-in `waitForExistence` equivalent as of Xcode 26. The polling workaround above remains the standard approach.

---

**Q: What is the difference between `.tap()` and `.click()`?**

A: `.tap()` is used on **iOS/iPadOS** (touch-based), while `.click()` is used on **macOS** (mouse-based). Using the wrong one on the wrong platform will cause a test failure.

```swift
// iOS
app.buttons["loginButton"].tap()

// macOS
app.buttons["loginButton"].click()
```

---

**Q: What is the difference between `.firstMatch` and `.element`?**

A:
- `.element` — resolves to the single matching element; fails with an error if there are multiple matches
- `.firstMatch` — resolves to the first matching element without raising an error for multiple matches; faster because the query stops at the first result

Use `.firstMatch` when you know there may be multiple matches and you want the first one. Use `.element` when you expect exactly one match and want a diagnostic error if that assumption is violated.

---

**Q: How do you query elements by type and accessibility label?**

A:
```swift
// By type only
app.buttons.firstMatch

// By accessibilityIdentifier — these two are equivalent
app.buttons["submitButton"]
app.buttons.matching(identifier: "submitButton").firstMatch

// By label (displayed text) — using NSPredicate
let predicate = NSPredicate(format: "label CONTAINS 'Submit'")
app.buttons.matching(predicate).firstMatch
```

---

**Q: How do you handle alerts in UI tests?**

A:
```swift
// Tap the "OK" button on any alert
app.alerts.firstMatch.buttons["OK"].tap()

// Wait for an alert and dismiss it
let alert = app.alerts.firstMatch
if alert.waitForExistence(timeout: 3) {
    alert.buttons["Allow"].tap()
}
```

---

**Q: What are `app.cells` in XCUITest and how do they map to SwiftUI?**

A: `app.cells` refers to `UITableViewCell` or `UICollectionViewCell` elements. XCUITest maps every UI component to an element type via the accessibility tree:

| Query | UIKit | SwiftUI |
|---|---|---|
| `app.buttons` | `UIButton` | `Button` |
| `app.staticTexts` | `UILabel` | `Text` |
| `app.textFields` | `UITextField` | `TextField` |
| `app.secureTextFields` | `UITextField` (secure) | `SecureField` |
| `app.switches` | `UISwitch` | `Toggle` |
| `app.cells` | `UITableViewCell` / `UICollectionViewCell` | `List` row |
| `app.tables` | `UITableView` | `List` |
| `app.collectionViews` | `UICollectionView` | `LazyVGrid` / `LazyHGrid` |
| `app.images` | `UIImageView` | `Image` |
| `app.sliders` | `UISlider` | `Slider` |
| `app.alerts` | `UIAlertController` | `Alert` |

In SwiftUI, set the identifier using `.accessibilityIdentifier()` modifier:

```swift
// SwiftUI production code
Button("Login") { }
    .accessibilityIdentifier("loginButton")

List {
    ForEach(items) { item in
        Text(item.title)
            .accessibilityIdentifier("cell_\(item.id)")
    }
}

// XCUITest — same as UIKit
app.buttons["loginButton"].tap()
app.cells["cell_123"].tap()
```

Note: complex SwiftUI custom views or containers like `VStack`/`Group` may appear as `other` type in the accessibility tree. Use **Accessibility Inspector** in Xcode to verify what XCUITest actually sees, and use `.accessibilityElement(children: .combine)` when needed.

---

**Q: How do you find elements that are not immediately visible (e.g., inside a scroll view)?**

A: Scroll to reveal the element, then interact with it:
```swift
let table = app.tables.firstMatch
table.swipeUp()

let cell = app.cells["targetCell"]
XCTAssertTrue(cell.waitForExistence(timeout: 3))
cell.tap()
```

---

**Q: How do you use Page Object Model (POM) in XCUITest?**

A: POM encapsulates UI element queries and interactions in dedicated screen objects, separating test logic from UI details:

```swift
struct LoginScreen {
    let app: XCUIApplication

    var emailField: XCUIElement { app.textFields["emailField"] }
    var passwordField: XCUIElement { app.secureTextFields["passwordField"] }
    var loginButton: XCUIElement { app.buttons["loginButton"] }

    func login(email: String, password: String) {
        emailField.tap()
        emailField.typeText(email)
        passwordField.tap()
        passwordField.typeText(password)
        loginButton.tap()
    }
}

// In test
func testLogin() {
    let login = LoginScreen(app: app)
    login.login(email: "user@example.com", password: "pass")
    XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 5))
}
```

---

**Q: How do you handle system permission dialogs (camera, location, notifications)?**

A:
```swift
// Use addUIInterruptionMonitor to handle system alerts
addUIInterruptionMonitor(withDescription: "Location Permission") { alert in
    if alert.buttons["Allow While Using App"].exists {
        alert.buttons["Allow While Using App"].tap()
        return true
    }
    return false
}

// Trigger the permission request
app.buttons["enableLocation"].tap()
app.tap() // Interact with app to trigger the monitor
```

Alternatively, use `app.launchArguments` to pre-authorize permissions via a test helper or use the `XCUIApplication` reset:

```swift
app.resetAuthorizationStatus(for: .location)
```

---

**Q: What is `XCUIApplication.resetAuthorizationStatus(for:)` and when would you use it?**

A: It resets a permission (e.g., `.camera`, `.location`, `.contacts`) to an undetermined state before the test runs, ensuring the system permission dialog appears reliably. Use it in `setUp` when your test needs to verify the permission request flow.

```swift
override func setUpWithError() throws {
    continueAfterFailure = false
    app.resetAuthorizationStatus(for: .camera)
    app.launch()
}
```

---

**Q: How do you simulate a swipe gesture?**

A:
```swift
app.tables.firstMatch.swipeUp()
app.tables.firstMatch.swipeDown()

// Swipe on a specific element
app.cells["myCell"].swipeLeft()
```

---

**Q: How do you take a screenshot during a UI test?**

A:
```swift
let screenshot = app.screenshot()
let attachment = XCTAttachment(screenshot: screenshot)
attachment.name = "Login Screen"
attachment.lifetime = .keepAlways
add(attachment)
```

---

**Q: How do you test a UIPickerWheel or date picker?**

A:
```swift
let picker = app.pickerWheels.firstMatch
picker.adjust(toPickerWheelValue: "March")
```

---

**Q: What is a test plan and how does it help with UI testing?**

A: A test plan (`.xctestplan`) is a JSON configuration file that defines which tests to run, environment variables, arguments, code coverage settings, and localization options. It allows running the same tests under different configurations (e.g., different languages, dark/light mode) without duplicating test code.

---

**Q: How do you run a UI test on a specific device or simulator configuration?**

A: Use Xcode's test plans or the `xcodebuild` command with `-destination`:

```bash
xcodebuild test \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -testPlan MyUITests
```

---

**Q: How do you test deep links or URL schemes?**

A:
```swift
let app = XCUIApplication()
app.launch()

let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
safari.launch()
safari.textFields["Address"].tap()
safari.textFields["Address"].typeText("myapp://profile/123\n")

// Handle the open-in prompt if needed
app.activate()
```

---

**Q: How do you measure UI test performance with `XCTMetrics`?**

A:
```swift
func testScrollingPerformance() {
    let app = XCUIApplication()
    app.launch()

    let options = XCTMeasureOptions()
    options.iterationCount = 5

    measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: options) {
        app.tables.firstMatch.swipeUp()
    }
}
```

---

**Q: What is the difference between `app.windows.firstMatch.groups.firstMatch` and `app.windows.matching(identifier:).firstMatch`?**

A:
- `app.windows.firstMatch.groups.firstMatch` — grabs the first available window then the first group inside it. Generic and works without knowing any identifiers, but fragile if multiple windows are open (sheets, popovers) since you may get the wrong one.
- `app.windows.matching(identifier: "com_apple_SwiftUI_Settings_window").firstMatch` — targets a specific window by its accessibility identifier. The identifier `com_apple_SwiftUI_Settings_window` is auto-generated by SwiftUI for the Settings scene on macOS.

```swift
// Generic — simple apps with one window
let group = app.windows.firstMatch.groups.firstMatch

// Precise — macOS SwiftUI apps with multiple windows/scenes
let settingsWindow = app.windows.matching(identifier: "com_apple_SwiftUI_Settings_window").firstMatch
```

Use `.firstMatch` chains for simple single-window apps. Use `.matching(identifier:)` on macOS when multiple windows can be open simultaneously (e.g., Settings window vs main window) to avoid accidentally targeting the wrong one.

---

**Q: Is `accessibilityIdentifier` only useful for XCUITest?**

A: Yes. `accessibilityIdentifier` is a string used to uniquely identify UI elements in tests without depending on localized text or visual appearance. It is purely a testing hook — VoiceOver and other assistive technologies completely ignore it. It has zero runtime cost or user-facing impact, so most teams leave it in production builds. Some codebases strip it in release builds anyway:

```swift
// Set in production code
loginButton.accessibilityIdentifier = "loginButton"

// Used in UI test
app.buttons["loginButton"].tap()

// Optionally stripped from release builds
#if DEBUG
button.accessibilityIdentifier = "loginButton"
#endif
```

For actual accessibility (VoiceOver), use these instead:

| Property | VoiceOver | XCUITest |
|---|---|---|
| `accessibilityIdentifier` | No | Yes |
| `accessibilityLabel` | Yes | Yes |
| `accessibilityHint` | Yes | No |
| `accessibilityValue` | Yes | No |

---

**Q: Does `accessibilityIdentifier` have to be unique within the whole app or just the screen?**

A: It does not have to be unique within the whole app — only within the **current query scope**. XCUITest resolves elements based on the query hierarchy, so the same identifier can exist on multiple screens without conflict as long as only one screen is visible at a time:

```swift
// Both screens can have a "submitButton" — no conflict
app.buttons["submitButton"].tap()  // finds the visible one
```

Within the **same screen**, duplicate identifiers cause ambiguity:

```swift
app.buttons["submitButton"].tap()          // ❌ ambiguous — may tap wrong one
app.buttons["submitButton"].firstMatch.tap() // taps the first one found
app.buttons["submitButton"].element.tap()    // ❌ fails — multiple matches
```

For repeated elements like table cells, scope your query to avoid ambiguity:

```swift
// Each cell has a "titleLabel" — scope to a specific cell
let cell = app.cells.element(boundBy: 0)
cell.staticTexts["titleLabel"].tap()  // scoped — no ambiguity
```

`element(boundBy:)` is the only way to access elements by index — `XCUIElementQuery` has no `[Int]` subscript, so `query[0]` doesn't compile.

```swift
// Verify multiple section headers in order
wait(for: sectionHeaderText.element(boundBy: 0), toShow: "text files")
wait(for: sectionHeaderText.element(boundBy: 1), toShow: "pdf files")
```

| Scope | Requirement |
|---|---|
| Across different screens | Can reuse identifiers safely |
| Within the same screen | Should be unique |
| Within a reusable cell | Same identifier repeats — scope query to parent cell |

# Find My — Apple SDET Interview

Role: SDET — automation in Swift / XCUI / XCTest to drive quality for the Find My app.


## What does SDET mean?

**SDET** stands for **Software Development Engineer in Test**.

It's a hybrid role: part software engineer, part QA. An SDET writes the **code that tests the product** rather than manually clicking through it. At Apple's Find My team that means building automation frameworks in Swift / XCTest / XCUI that run on CI to catch bugs before shipping.

The difference from a regular QA:

- **QA** — finds bugs manually, writes test cases in documents.

- **SDET** — writes automated test code, builds test infrastructure, measures performance, integrates with CI pipelines.


## What is the best way to test AirTags?

Testing AirTags involves multiple layers:

**Unit tests** — test the business logic in isolation (pairing state machine, naming, ownership transfer).

**UI tests (XCUI)** — automate the setup flow in the Find My app: detect accessory, name it, confirm registration.

**Hardware-in-the-loop** — use a physical AirTag (or Apple's internal simulator/stub) connected to a test device to validate Bluetooth discovery, UWB precision finding, and NFC tap-to-pair.

**Test layers:**

1. Mock the accessory layer for pure logic tests — no physical hardware needed.

2. Use `XCUIApplication` to drive the onboarding UI end-to-end.

3. Use `XCTMetrics` (specifically `XCTClockMetric` and `XCTMemoryMetric`) to measure pairing duration and catch regressions.

4. Run on a device farm (e.g., Xcode Cloud or internal CI) with real hardware for full signal validation.


## If AirTag registration is taking too long, how do you debug which component is causing the delay?

Break the registration flow into measurable segments and time each one independently:

```swift
// Instrument each phase with XCTClockMetric
func testAirTagRegistrationPerformance() {
    let app = XCUIApplication()
    app.launch()

    measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
        // Tap "Add New Item"
        app.buttons["Add Item"].tap()

        // Wait for Bluetooth discovery
        let foundAccessory = app.staticTexts["AirTag"].waitForExistence(timeout: 10)
        XCTAssertTrue(foundAccessory, "AirTag not discovered in time")

        // Tap Connect
        app.buttons["Connect"].tap()

        // Wait for registration confirmation screen
        let registered = app.staticTexts["AirTag Added"].waitForExistence(timeout: 15)
        XCTAssertTrue(registered, "Registration did not complete in time")
    }
}
```

**Phases to isolate:**

1. **Bluetooth discovery** — time from scan start to accessory found. If slow, suspect BT stack or background throttling.

2. **NFC/UWB handshake** — tap-to-pair latency. Instrument with `os_signpost` in the framework layer.

3. **iCloud activation** — network call to register ownership. Add a mock/stub to isolate from network latency.

4. **UI transition** — time from API response to confirmation screen rendered.

**Tools:**

- `os_signpost(.begin / .end)` — marks intervals visible in Instruments → Points of Interest.

- **Instruments → Time Profiler** — see which thread/call is blocking.

- **Instruments → Network** — confirm iCloud activation call latency.

- `XCTClockMetric` in `measure {}` block — catches regressions in CI automatically.


## What is os_signpost and how do you use it?

`os_signpost` is Apple's low-overhead logging API for marking **named time intervals** in your code. Those intervals appear as colored spans in **Instruments → Points of Interest**, so you can visually see exactly how long each phase of a flow took — without guessing from a stack trace.

It lives in the `os` framework:

```swift
import os
```


### The three pieces

**1. `OSLog` — the channel that owns the signposts**

```swift
let log = OSLog(subsystem: "com.apple.findmy", category: "AirTagRegistration")
```

Think of `subsystem` as the app and `category` as the feature. Instruments filters by these so you see only the spans you care about.

**2. `OSSignpostID` — a unique ID for one instance of an interval**

```swift
let spid = OSSignpostID(log: log)
```

If you run the same code concurrently (e.g., pairing two AirTags at once), each call gets its own `spid` so their spans don't get mixed together in Instruments.

**3. `os_signpost(.begin)` / `os_signpost(.end)` — the actual markers**

```swift
os_signpost(.begin, log: log, name: "BT Discovery", signpostID: spid)
// ... code being measured ...
os_signpost(.end,   log: log, name: "BT Discovery", signpostID: spid)
```

The `name` string must match exactly between `.begin` and `.end` — that's how Instruments draws a single span.


### Full example — timing AirTag registration phases

```swift
import os

private let registrationLog = OSLog(subsystem: "com.apple.findmy", category: "AirTagRegistration")

func registerAirTag(accessory: Accessory) async throws {
    let spid = OSSignpostID(log: registrationLog)

    // Phase 1: Bluetooth discovery
    os_signpost(.begin, log: registrationLog, name: "BT Discovery", signpostID: spid)
    try await bluetoothStack.discover(accessory)
    os_signpost(.end,   log: registrationLog, name: "BT Discovery", signpostID: spid)

    // Phase 2: NFC/UWB handshake
    os_signpost(.begin, log: registrationLog, name: "NFC Handshake", signpostID: spid)
    try await uwbStack.handshake(accessory)
    os_signpost(.end,   log: registrationLog, name: "NFC Handshake", signpostID: spid)

    // Phase 3: iCloud activation
    os_signpost(.begin, log: registrationLog, name: "iCloud Activation", signpostID: spid)
    try await iCloudService.register(accessory)
    os_signpost(.end,   log: registrationLog, name: "iCloud Activation", signpostID: spid)
}
```

In Instruments you will see three back-to-back colored bars — **BT Discovery**, **NFC Handshake**, **iCloud Activation** — and you can instantly see which one is fat (slow).


### Event signposts (single point in time)

Not every interesting thing is an interval. For one-shot events use `.event`:

```swift
os_signpost(.event, log: registrationLog, name: "User Tapped Connect")
```

This drops a single vertical line in Instruments, useful for correlating user actions with the timeline.


### Adding data to a signpost

You can attach a formatted string that shows up as a tooltip in Instruments:

```swift
os_signpost(.begin, log: registrationLog, name: "iCloud Activation", signpostID: spid,
            "%{public}s accessoryID: %@", "start", accessory.id)
os_signpost(.end,   log: registrationLog, name: "iCloud Activation", signpostID: spid,
            "%{public}s statusCode: %d", "end", responseCode)
```

Use `%{public}s` for strings you want visible in release builds; use `%{private}s` (the default) for anything sensitive — private strings are redacted in logs captured outside a debug session.


### os_signpost vs XCTClockMetric — when to use each

| | `os_signpost` | `XCTClockMetric` |
|---|---|---|
| **Where results appear** | Instruments (visual timeline) | Xcode test results (numeric) |
| **CI regression detection** | No — manual inspection only | Yes — fails automatically if threshold exceeded |
| **Granularity** | Any code path, any framework layer | Only inside a `measure {}` block |
| **Overhead** | Extremely low (async ring buffer) | Low |
| **Best for** | Root-cause debugging a slowdown | Preventing a regression from shipping |

In practice you use both: `os_signpost` to **find** which phase is slow during investigation, `XCTClockMetric` to **guard** against that phase regressing again in CI.


## How do you write unit tests for AirTag registration logic?

```swift
import Testing

@Test("AirTag registration succeeds with valid accessory")
func airTagRegistrationSuccess() async throws {
    let mockAccessory = MockAccessory(id: "AA:BB:CC:DD:EE:FF", name: "My AirTag")
    let mockService = MockRegistrationService(shouldSucceed: true)
    let viewModel = AirTagRegistrationViewModel(service: mockService)

    await viewModel.register(accessory: mockAccessory)

    #expect(viewModel.state == .registered)
    #expect(viewModel.registeredName == "My AirTag")
}

@Test("Registration fails gracefully on network error")
func airTagRegistrationFailure() async throws {
    let mockAccessory = MockAccessory(id: "AA:BB:CC:DD:EE:FF", name: "My AirTag")
    let mockService = MockRegistrationService(shouldSucceed: false, error: .networkUnavailable)
    let viewModel = AirTagRegistrationViewModel(service: mockService)

    await viewModel.register(accessory: mockAccessory)

    #expect(viewModel.state == .failed)
    #expect(viewModel.errorMessage != nil)
}
```

Key principle: inject a `MockRegistrationService` so tests never hit real iCloud — fast, deterministic, runnable on CI with no hardware.


## How do you write UI tests for AirTag registration?

```swift
import XCTest

final class AirTagRegistrationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--mock-airtag-accessory"]  // tells the app to use a stub accessory
        app.launch()
    }

    func testAirTagRegistrationFlow() {
        // Navigate to Add Item
        app.buttons["Add Item"].tap()

        // Accessory should be discovered
        let accessoryCell = app.cells["AirTag"].firstMatch
        XCTAssertTrue(accessoryCell.waitForExistence(timeout: 10))
        accessoryCell.tap()

        // Name the AirTag
        let nameField = app.textFields["Item Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("My Keys")
        app.buttons["Continue"].tap()

        // Confirm registration success screen
        let confirmation = app.staticTexts["AirTag Added"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 15))
    }

    func testAirTagRegistrationPerformance() {
        measure(metrics: [XCTClockMetric()]) {
            app.buttons["Add Item"].tap()
            app.cells["AirTag"].firstMatch.waitForExistence(timeout: 10)
            app.cells["AirTag"].firstMatch.tap()
            app.buttons["Continue"].tap()
            app.staticTexts["AirTag Added"].waitForExistence(timeout: 15)
            app.terminate()
            app.launch()
        }
    }
}
```


## What is XCTClockMetric and XCTMemoryMetric?

Both are `XCTMetric` types used inside a `measure(metrics:) {}` block. Xcode runs the block multiple times, records each metric, computes an average, and compares it to a saved **baseline** — failing the test if the result drifts beyond the allowed threshold.


### XCTClockMetric

Measures **wall-clock time** — how long the code inside the block actually takes to run from start to finish.

Use it to catch slowdowns: if registration used to take 1.2s and now takes 3s, the test fails.

```swift
func testAirTagDiscoverySpeed() {
    let app = XCUIApplication()
    app.launch()

    measure(metrics: [XCTClockMetric()]) {
        app.buttons["Add Item"].tap()
        // Fails if AirTag discovery takes longer than the baseline
        XCTAssertTrue(app.cells["AirTag"].waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
    }
}
```

After the first run, right-click the test in Xcode → **Set Baseline** to lock in the expected duration. Future runs fail if they exceed it.


### What is the threshold and how does Xcode calculate it?

Xcode does **not** use a fixed number like "100ms". It uses a **percentage above the baseline** — the default is **10%**.

So if your baseline is **1.2 seconds**, the test fails when the measured average exceeds **1.32 seconds** (1.2 × 1.10).

That 10% is called the `maxStandardDeviations` tolerance in Xcode's internals, but in practice it behaves as a percentage band around the baseline mean.

**How Xcode arrives at one number:**

The `measure {}` block runs **5 iterations** by default (the first is a warm-up and is discarded). Xcode takes the **average** of the remaining 4 runs and compares that average to the baseline. If `average > baseline × 1.10` the test fails.

```
baseline = 1.200 s   (set by you after the first passing run)
threshold = 1.200 × 1.10 = 1.320 s
measured average = 1.350 s  →  FAIL  ❌
measured average = 1.300 s  →  PASS  ✅
```


### Changing the iteration count

```swift
let options = XCTMeasureOptions()
options.iterationCount = 10   // more iterations = more stable average
measure(metrics: [XCTClockMetric()], options: options) {
    // ...
}
```

More iterations reduce noise but slow down the test suite. 5 (default) is fine for most flows; bump to 10 for flaky tests on CI.


### Changing the threshold per-test

You cannot change the 10% band in code — it is set in the baseline file. After running the test, click **Edit** next to the baseline in Xcode's test result, and you can type a custom **Max STDDEV %** (e.g., 20% for a network-heavy flow that is inherently variable).

Alternatively, widen tolerance by setting a looser baseline value (e.g., record the baseline on a slow device so fast devices always pass comfortably).


### Where baselines are stored

Xcode stores baselines in a `.xcbaseline` bundle inside your `.xcresult` artifacts and, if you check it in, in:

```
<Target>/<TestFile>.xcbaseline
```

Commit this file to version control so every CI machine uses the same reference numbers. If you don't commit it, each CI run starts with no baseline and the test skips the comparison on the first run (it just records), which means regressions are invisible until a human re-sets the baseline locally.

**Practical rule of thumb for Apple-hardware CI:**

- **Clock (wall time):** 10% default is usually fine for pure Swift logic. For flows that touch BLE/network, loosen to **20–25%** because radio latency has inherent jitter.

- **Memory:** 5–10% is reasonable; memory should be more deterministic than time.

- **CPU:** 15–20% because CPU scheduling varies more across CI machines.


### XCTMemoryMetric

Measures **memory usage** (in bytes) during the block — specifically the peak physical memory footprint of the app process.

Use it to catch memory bloat: if loading 2000 employees starts consuming 300 MB instead of 50 MB, the test fails.

```swift
func testEmployeeListMemoryUsage() {
    let app = XCUIApplication()
    app.launch()

    measure(metrics: [XCTMemoryMetric()]) {
        // Navigate to the employee list that loads 2000 items
        app.buttons["Employees"].tap()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
    }
}
```


### Using both together

```swift
func testRegistrationPerformance() {
    let app = XCUIApplication()
    app.launchArguments = ["--mock-airtag-accessory"]
    app.launch()

    measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
        app.buttons["Add Item"].tap()
        app.cells["AirTag"].firstMatch.tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["AirTag Added"].waitForExistence(timeout: 15))
        app.terminate()
        app.launch()
    }
}
```

- `XCTClockMetric` tells you **how slow** it is.

- `XCTMemoryMetric` tells you **how heavy** it is.

Together they give you a full picture of whether a change regressed performance or memory in CI.


## How do you measure and prevent performance regressions in CI?

Use `measure(metrics:)` with a baseline:

```swift
func testRegistrationDuration() {
    let metrics: [XCTMetric] = [
        XCTClockMetric(),
        XCTMemoryMetric(),
        XCTCPUMetric()
    ]
    let options = XCTMeasureOptions()
    options.iterationCount = 5

    measure(metrics: metrics, options: options) {
        // run the registration flow
    }
}
```

- Xcode records a **baseline** on first run. Subsequent runs fail if the metric exceeds the baseline by more than the allowed threshold.

- Run these on a dedicated CI device (not a simulator) for stable, reproducible numbers.

- Add `XCTAttachment` to capture logs or screenshots on failure for easier triage.


## How do you test Find My for Apple devices (iPhone, iPad, Mac, Apple Watch)?

Find My for first-party Apple devices involves different signals and flows than AirTags:

**Key differences from AirTags:**

- Devices report location via GPS/Wi-Fi/cellular, not just BLE proximity.

- Devices can show a **last known location**, go into **Lost Mode**, trigger **Play Sound**, or be **remotely erased**.

- Devices owned by family members appear under the People / Devices tab, not the Items tab.

**Test layers:**

1. **Unit tests** — test the view-model logic for each action (Lost Mode state machine, sound-trigger command dispatch, erase confirmation flow) with a mock `FindMyDeviceService`.

2. **UI tests (XCUI)** — automate selecting a device on the map, tapping each action button, and verifying the resulting UI state.

3. **Network layer tests** — mock iCloud endpoints to verify the app sends the correct command payload and handles 200/4xx/5xx responses.

4. **Location update tests** — inject synthetic `CLLocation` updates via a mock `CLLocationManager` and assert the map annotation moves to the new coordinate.

```swift
@Test("Lost Mode activates and shows confirmation banner")
func lostModeActivation() async throws {
    let mockService = MockFindMyDeviceService(commandResult: .success)
    let viewModel = DeviceDetailViewModel(service: mockService)

    await viewModel.activateLostMode(contactPhone: "555-1234", message: "Please call me")

    #expect(viewModel.deviceState == .lost)
    #expect(viewModel.bannerMessage == "Lost Mode Enabled")
}
```


## How do you test the "Play Sound" feature on a remote device?

Play Sound fires a push notification to the target device, which then plays an alert tone. Testing it end-to-end requires decoupling the UI action from the actual push delivery.

**Unit test — command dispatch:**

```swift
@Test("Play Sound sends correct command to service")
func playSoundDispatchesCommand() async throws {
    let mockService = MockFindMyDeviceService()
    let viewModel = DeviceDetailViewModel(service: mockService)

    await viewModel.playSound()

    #expect(mockService.lastCommand == .playSound)
    #expect(viewModel.playSoundState == .sent)
}
```

**UI test — button state after tap:**

```swift
func testPlaySoundButtonShowsConfirmation() {
    app.launchArguments = ["--mock-device-online"]
    app.launch()

    app.cells["My iPhone"].firstMatch.tap()
    app.buttons["Play Sound"].tap()

    XCTAssertTrue(app.staticTexts["Sound Playing"].waitForExistence(timeout: 5))
}
```

**Edge cases to cover:**

- Device is offline → UI shows "Sound will play when device comes online" pending state.

- Command times out → UI shows error banner and re-enables the button.

- Device is already playing a sound → button shows "Stop Sound" state.


## How do you test offline finding (the crowdsourced location network)?

Offline finding uses nearby Apple devices to relay an encrypted location beacon. From an SDET perspective you cannot trigger real crowdsourced relays in CI — you rely on stubbing.

**Strategy:**

1. Stub the `OfflineFindingService` to return a synthetic location with a `confidence` and `timestamp`.

2. Assert the map annotation renders the location with a visual indicator (e.g., a dimmed pin or "Last Seen" label) distinct from a live GPS fix.

3. Assert the "Last Seen" timestamp is formatted correctly in the detail view.

```swift
@Test("Offline location renders Last Seen label with correct timestamp")
func offlineLocationShowsLastSeen() async throws {
    let offlineLocation = FindMyLocation(
        coordinate: CLLocationCoordinate2D(latitude: 37.33, longitude: -122.03),
        timestamp: Date(timeIntervalSinceNow: -3600),  // 1 hour ago
        source: .offlineCrowdsourced
    )
    let mockService = MockFindMyDeviceService(location: offlineLocation)
    let viewModel = DeviceDetailViewModel(service: mockService)

    await viewModel.loadLocation()

    #expect(viewModel.locationSource == .offlineCrowdsourced)
    #expect(viewModel.lastSeenLabel.contains("1 hour ago"))
}
```


## How do you test location accuracy and map annotation updates?

Inject a mock `CLLocationManager` that emits a sequence of `CLLocation` objects and assert the map view model reacts correctly.

```swift
@Test("Map annotation updates when a new location is received")
func locationUpdateMovesAnnotation() async throws {
    let mockLocationSource = MockLocationSource()
    let viewModel = DeviceMapViewModel(locationSource: mockLocationSource)

    let newCoord = CLLocationCoordinate2D(latitude: 37.78, longitude: -122.41)
    await mockLocationSource.emit(CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude))

    #expect(viewModel.deviceAnnotation?.coordinate.latitude == newCoord.latitude)
    #expect(viewModel.deviceAnnotation?.coordinate.longitude == newCoord.longitude)
}
```

**Additional cases:**

- Accuracy degrades (large `horizontalAccuracy`) → annotation shows accuracy circle expanding.

- Location is `nil` (device never reported) → map shows "Location Not Available" empty state.

- Two rapid location updates → only the latest coordinate is shown (debounce logic).


## How do you test Family Sharing / shared device visibility?

The People tab and shared device list depend on the current user's iCloud family group. Test this by injecting a mock `FamilySharingService` with a controlled set of members.

```swift
@Test("Devices tab lists all family members' devices")
func familyDevicesPopulated() async throws {
    let family = [
        FamilyMember(name: "Alice", devices: [MockDevice(name: "Alice's iPhone")]),
        FamilyMember(name: "Bob",   devices: [MockDevice(name: "Bob's iPad")])
    ]
    let mockService = MockFamilySharingService(members: family)
    let viewModel = DevicesTabViewModel(familyService: mockService)

    await viewModel.loadDevices()

    #expect(viewModel.sections.count == 2)
    #expect(viewModel.sections[0].title == "Alice")
    #expect(viewModel.sections[1].devices.first?.name == "Bob's iPad")
}
```

**UI test — device list renders correctly:**

```swift
func testFamilyDeviceListDisplayed() {
    app.launchArguments = ["--mock-family-two-members"]
    app.launch()

    app.buttons["Devices"].tap()

    XCTAssertTrue(app.cells["Alice's iPhone"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.cells["Bob's iPad"].exists)
}
```


## How do you test geofence notifications (Leave / Arrive)?

Find My can alert you when a device or person leaves or arrives at a location. The notification logic is driven by geofence regions (`CLCircularRegion`). Test it by simulating region-crossing events.

```swift
@Test("Arrive notification triggers when device enters region")
func arriveNotificationOnRegionEntry() async throws {
    let region = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 37.33, longitude: -122.03),
        radius: 200,
        identifier: "Home"
    )
    let mockNotifier = MockNotificationService()
    let monitor = GeofenceMonitor(notifier: mockNotifier)

    monitor.didEnterRegion(region)

    #expect(mockNotifier.lastNotification?.type == .arrive)
    #expect(mockNotifier.lastNotification?.locationName == "Home")
}
```

**Edge cases:**

- Device enters then immediately exits → "Leave" notification fires only once, not repeatedly.

- Two devices share the same geofence → each triggers its own independent notification.

- Notifications are disabled by the user → `mockNotifier` receives no calls.


## How do you test remote erase (Erase This Device)?

Remote erase is irreversible, so UI tests must confirm the confirmation dialog appears and the action is gated behind explicit user consent. Never call a real erase endpoint in tests.

```swift
func testEraseDeviceRequiresConfirmation() {
    app.launchArguments = ["--mock-device-online"]
    app.launch()

    app.cells["My Mac"].firstMatch.tap()
    app.buttons["Erase This Device"].tap()

    // Confirmation sheet must appear before any erase call is made
    let confirmSheet = app.sheets["Erase My Mac?"]
    XCTAssertTrue(confirmSheet.waitForExistence(timeout: 5))

    // Dismiss — no erase should have been triggered
    confirmSheet.buttons["Cancel"].tap()
    XCTAssertFalse(app.staticTexts["Erase Initiated"].exists)
}

@Test("Erase command is not sent when user cancels")
func eraseCommandNotSentOnCancel() async throws {
    let mockService = MockFindMyDeviceService()
    let viewModel = DeviceDetailViewModel(service: mockService)

    viewModel.userCancelledErase()

    #expect(mockService.commandCallCount == 0)
}
```


## General SDET interview tips for this role

- Emphasize **Swift-first testing**: Swift Testing (`@Test`, `#expect`) for unit tests, XCTest/XCUI for UI and performance.

- Know the difference between **unit, integration, and UI tests** and when to use each.

- Be ready to discuss **test pyramid** — most coverage at unit level, fewer expensive UI tests.

- Understand **mocking and dependency injection** — critical for testing hardware-dependent flows like AirTag without real devices.

- Know **Instruments** tools: Time Profiler, Leaks, Network, Points of Interest (os_signpost).

- Be familiar with **Xcode Cloud** or similar CI pipelines for running tests automatically on PRs.

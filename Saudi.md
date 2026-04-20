# Saudi Interview Questions

Q: You have a wearable device that monitors a patient's pulse and connects to an iOS app over Bluetooth. Can the app be woken up when the pulse is too low?

A: Yes, but with constraints depending on app state:

**If the app is in the foreground or background (not terminated):**
- Use **Core Bluetooth** (`CBCentralManager`) to maintain a BLE connection.
- The wearable sends a notification/indication when pulse drops below threshold.
- iOS delivers the BLE event to the app even in the background via the `centralManager(_:didUpdateValueFor:)` delegate callback.
- The app gets background execution time to process the alert and trigger a local notification.

**If the app is terminated:**
- Declare `bluetooth-central` in `UIBackgroundModes` (Info.plist).
- Instantiate `CBCentralManager` with a **restoration identifier**: `CBCentralManagerOptionRestoreIdentifierKey`.
- iOS can relaunch the terminated app in the background when a subscribed BLE characteristic value changes.
- Implement `centralManager(_:willRestoreState:)` to reconnect and resume monitoring.
- Once relaunched, post a `UNUserNotificationCenter` local notification to alert the user.

**Key limitations:**
- The wearable must support BLE notifications/indications on the pulse characteristic.
- iOS may delay relaunch under heavy system load.
- The app has limited background time (~30 seconds) to handle the event before being suspended again.
- For critical medical use, consider a dedicated Bluetooth accessory (MFi) or push notifications via an intermediary server for more reliable delivery.

**Summary flow:**

1. Wearable detects low pulse → sends BLE notification.
2. iOS relaunches app in background (state restoration).
3. App receives `didUpdateValueFor` callback.
4. App fires a local notification to wake the user.


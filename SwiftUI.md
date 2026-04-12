# SwiftUI questions

## What is SwiftUI, and how does it differ from UIKit?

SwiftUI is Apple's declarative UI framework introduced in iOS 13. It allows developers to build UIs using a declarative syntax, making UI code more concise and easier to understand. Unlike UIKit, SwiftUI eliminates the need for a lot of boilerplate code and manual UI updates.

## Explain the concept of state in SwiftUI.

State in SwiftUI represents values that can change over time and trigger UI updates. It is used to manage the dynamic content and behavior of a view.

## What is the purpose of the @State property wrapper?

The @State property wrapper is used to declare a state property in a SwiftUI view. It indicates that the property's value is stored outside the view and should be preserved across view updates.

## How does SwiftUI handle data binding?

SwiftUI uses data binding to establish a two-way connection between the UI and the underlying data. When the data changes, the UI updates automatically, and vice versa.

## What is the purpose of the ObservableObject protocol?

The ObservableObject protocol is used to create classes that can be observed for changes. It is often used in conjunction with the @ObservedObject property wrapper to update views when the observed object's state changes.

## Explain the concept of a View in SwiftUI.

In SwiftUI, a View is a protocol that represents the visual structure and layout of the user interface. Views can be composed hierarchically, and the framework automatically manages updates to the UI based on state changes.

## What is the purpose of the NavigationView and List views in SwiftUI?

NavigationView provides a navigation UI, allowing users to navigate between different views in an app. List is a container view that displays a scrolling list of views, often used in conjunction with ForEach to display dynamic lists of data.

## How do you perform navigation between views in SwiftUI?

Navigation in SwiftUI is typically done using the NavigationLink view or programmatically using the NavigationLink(destination:isActive:label:) initializer. It allows for seamless navigation between different views.

## Explain the concept of a Binding in SwiftUI.

A Binding is a two-way connection to a value that can be passed around in SwiftUI. It allows a child view to modify a value owned by a parent view.

## What is the purpose of the EnvironmentObject property wrapper?

EnvironmentObject is used to share an observable object (conforming to ObservableObject) across multiple views in a SwiftUI hierarchy. It allows data to be passed down the view hierarchy without the need for manual passing through each level.

## When do we use some in swift?

In Swift, the `some` keyword is used in a few different contexts:

1. **Opaque Return Types:** When defining functions or properties whose return types are protocols or protocol compositions, you can use `some` to specify an opaque return type. This allows the compiler to infer the concrete type returned by the function or property, without exposing the implementation details. For example:

   ```swift
   protocol Shape {
       // protocol definition
   }

   func createShape() -> some Shape {
       // return a concrete type that conforms to Shape
   }
   ```

2. **View Builders in SwiftUI:** In SwiftUI, `some View` is commonly used in view builders to represent a type-erased view. This allows views to return different types of views dynamically, while ensuring that the views conform to the `View` protocol. For example:

   ```swift
   struct MyView: View {
       var body: some View {
           // return a dynamic view
       }
   }
   ```

3. **Existential Types:** When working with existential types (e.g., protocol types), `some` can be used to refer to a concrete type that conforms to a protocol. This is similar to how `some` is used with opaque return types but can also be used in other contexts where existential types are involved.

Overall, `some` is used to express the idea of an opaque or unknown type, typically when working with protocols, generics, or SwiftUI views. It helps improve type safety and encapsulation while allowing for flexible and dynamic behavior.

## What is `.debounce` in SwiftUI, where is it defined, and when/how do you use it?

### Where it's defined

`.debounce` is defined in the **Combine** framework, as an operator on `Publisher`. It is NOT a SwiftUI-specific API — it lives in `Combine.Publisher` and is used alongside SwiftUI through `@Published` properties or other Combine publishers.

```swift
import Combine
```

### What it does

`.debounce(for:scheduler:)` waits until a publisher has been silent for a specified duration before emitting the most recent value. It suppresses rapid successive values and only forwards one after the pause.

### When to use it

- **Search fields**: avoid firing a network request on every keystroke — wait until the user stops typing.
- **Form validation**: don't validate on every character change, only after the user pauses.
- **Resize/scroll events**: coalesce rapid UI events into a single action.

### How to use it

**Example: debouncing a search field in SwiftUI**

```swift
import SwiftUI
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.fetchResults(for: query)
            }
            .store(in: &cancellables)
    }

    private func fetchResults(for query: String) {
        // perform search/network call
        results = query.isEmpty ? [] : ["Result for \(query)"]
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack {
            TextField("Search...", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

            List(viewModel.results, id: \.self) { result in
                Text(result)
            }
        }
    }
}
```

### Key parameters

| Parameter   | Description |
|-------------|-------------|
| `for:`      | The quiet period (e.g. `.seconds(0.5)`) before emitting |
| `scheduler:` | Where to deliver the value — typically `DispatchQueue.main` for UI updates |

### `.debounce` vs `.throttle`

- **`.debounce`** — emits only after the source has been silent for the given duration. Best for "fire after user stops."
- **`.throttle`** — emits at most once per interval regardless of silence. Best for "fire at a steady rate."


## Explain cancellables

When the object owning `cancellables` is deallocated:
1. `deinit` is called
2. All stored properties are destroyed, including the `Set<AnyCancellable>`
3. When `AnyCancellable` is destroyed, it **automatically calls `.cancel()`** on itself

So cancellation **does happen** — but it's triggered by **ARC memory deallocation**, not by `deinit` explicitly.

### You Do NOT Need to Do This:
```swift
deinit {
    cancellables.forEach { $0.cancel() } // ❌ unnecessary
    cancellables.removeAll()             // ❌ also unnecessary
}
```

### The Cleanup is Automatic — But Timing Matters

The issue is **when** the object gets deallocated:

```swift
class MyViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in print("tick") }
            .store(in: &cancellables) // ✅ cancelled when VM deallocates
    }
}
```

If `MyViewModel` is **retained longer than expected** (e.g. retain cycle), the cancellables **won't cancel** either — because `deinit` never gets called.

### When You DO Need Manual Cancellation:
```swift
// If you need to cancel BEFORE deallocation
func stopListening() {
    cancellables.removeAll() // triggers cancel on all
}

// Or cancel a specific one
var specificTask: AnyCancellable?
specificTask?.cancel()
```

### Cancellables Summary
| Scenario | Cancellation happens? |
|---|---|
| Object deallocates normally | ✅ Yes, automatically |
| Retain cycle exists | ❌ No, deinit never called |
| You need early cancellation | ⚠️ Manual cancel needed |

The real thing to watch out for is **retain cycles** — that's what prevents the automatic cleanup from ever happening.

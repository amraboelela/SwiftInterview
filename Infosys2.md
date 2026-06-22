# Infosys 2 questions


## If you get a list of 2000 employees from an API, how do you handle lazy loading using List or ForEach in SwiftUI?

**Use `List` — it lazy-loads by default.**

`List` in SwiftUI is backed by `UITableView` under the hood. It only renders the rows that are currently visible on screen, automatically recycling cells as the user scrolls. This means even with 2000 items, only ~20-30 views are alive in memory at any given time.

`ForEach` inside a `ScrollView`, by contrast, renders **all** rows upfront and holds them in memory — that's 2000 views created immediately, which causes slow startup and high memory usage.

### Recommended approach

If `Employee` conforms to `Identifiable`, SwiftUI finds the `id` automatically:

```swift
struct Employee: Identifiable {
    let id: Int
    let name: String
}

struct EmployeeListView: View {
    @StateObject private var viewModel = EmployeeViewModel()

    var body: some View {
        List(viewModel.employees) { employee in  // id inferred from Identifiable
            EmployeeRow(employee: employee)
        }
        .task {
            await viewModel.loadEmployees()
        }
    }
}
```

If `Employee` does **not** conform to `Identifiable`, you must pass the key path explicitly:

```swift
// Using a unique property
List(viewModel.employees, id: \.id) { employee in
    EmployeeRow(employee: employee)
}

// Or id: \.self if Employee is Hashable (less preferred — use a stable unique id)
List(viewModel.employees, id: \.self) { employee in
    EmployeeRow(employee: employee)
}
```

### Why `List` over `ForEach` + `ScrollView`

| | `List` | `ForEach` in `ScrollView` |
|---|---|---|
| Renders all rows upfront | No — lazy | Yes — eager |
| Memory with 2000 items | Low (only visible rows) | High (all 2000 views) |
| Built-in scroll performance | Yes | No |
| Cell reuse | Yes | No |

### Pagination — load more as user scrolls

For very large datasets, add server-side pagination triggered when the user nears the end of the list:

```swift
List(viewModel.employees) { employee in
    EmployeeRow(employee: employee)
        .onAppear {
            if employee == viewModel.employees.last {
                Task { await viewModel.loadNextPage() }
            }
        }
}
```

### ViewModel

```swift
@MainActor
class EmployeeViewModel: ObservableObject {
    @Published var employees: [Employee] = []
    private var currentPage = 1
    private let pageSize = 50

    func loadEmployees() async {
        employees = await APIService.fetchEmployees(page: 1, pageSize: pageSize)
    }

    func loadNextPage() async {
        currentPage += 1
        let result = await APIService.fetchEmployees(page: currentPage, pageSize: pageSize)
        employees.append(contentsOf: result)
    }
}
```

### Key points to mention in an interview

- `List` is lazy by default — it only renders visible rows, just like `UITableView`.

- Never use `ForEach` inside `ScrollView` for large datasets — it eagerly creates all views and is not performant.

- Combine `List` with pagination (`onAppear` on the last item) to avoid loading all 2000 records at once from the API.

- Use `@StateObject` + `async/await` with `.task` modifier for clean async data loading.

- `LazyVStack` inside `ScrollView` is a middle ground — it's lazy like `List` but lacks built-in cell reuse and is less performant than `List` for data-heavy rows.


### LazyVStack + ForEach

```swift
ScrollView {
    LazyVStack {
        ForEach(viewModel.employees) { employee in
            EmployeeRow(employee: employee)
        }
    }
}
```

`LazyVStack` makes `ForEach` lazy — rows are created on demand as they scroll into view, not all at once. This fixes the eager-rendering problem of plain `ForEach` + `ScrollView`.

However it is still inferior to `List` because:

- **No cell reuse** — once a row is rendered it stays in memory, `List` recycles off-screen cells.

- **No built-in separators, swipe actions, or pull-to-refresh** — you have to build those yourself.

- **Higher memory** at scale — with 2000 rows, after scrolling to the bottom all 2000 views are in memory. `List` keeps only the visible ones alive.

**Rule of thumb:** use `LazyVStack` + `ForEach` when you need custom layout/styling that `List` can't provide. For a straightforward employee list, stick with `List`.

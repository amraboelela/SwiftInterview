# Realm DB

## What is Core Data, and how does it differ from Realm Database?

### Core Data
Apple's native framework for managing object graphs and persisting data on Apple platforms.

**Key features:**
- Object-graph management with entities and relationships
- Persistent store support (SQLite, XML, binary)
- Interface Builder integration
- Undo/redo support
- Batch updates

### Realm Database
A third-party, cross-platform mobile database popular for its simplicity and real-time sync.

**Key features:**
- Object-oriented model with native Swift/Kotlin objects
- Real-time collaboration: changes propagate instantly to all connected users
- Fast read/write performance via efficient storage and querying
- Cross-platform (iOS, Android)
- Built-in thread safety
- Simple API with low learning curve

### Key Differences

| | Core Data | Realm |
|---|---|---|
| Provider | Apple (native) | Third-party |
| Real-time sync | No | Yes |
| Cross-platform | No (Apple only) | Yes |
| Ease of use | Steeper curve | Simpler API |

## Is Realm a non-SQL database?

Yes. Realm is NoSQL — it uses an object-oriented model rather than tables and SQL. Data is queried using Realm's own query language that works naturally with native objects. This makes it well-suited for mobile apps where the data maps directly to Swift/Kotlin classes.

## Explain the concept of Object Server in Realm.

The Object Server is Realm's centralized sync server that enables real-time collaboration:

- **Live sync**: Changes from one client are immediately pushed to all other connected clients.
- **Conflict resolution**: Simultaneous edits are resolved automatically to maintain consistency.
- **Subscription model**: Clients subscribe to portions of data, reducing unnecessary transfers.

## How do you define relationships between objects in Realm?

Realm supports two relationship types:

### To-One
```swift
class Address: Object {
    @Persisted var street: String = ""
    @Persisted var city: String = ""
}

class Person: Object {
    @Persisted var name: String = ""
    @Persisted var address: Address?
}
```

### To-Many
```swift
class Player: Object {
    @Persisted var name: String = ""
    @Persisted var jerseyNumber: Int = 0
}

class Team: Object {
    @Persisted var teamName: String = ""
    let players = List<Player>()
}
```

### Usage
```swift
let person = Person()
person.address = Address()

let team = Team()
team.players.append(objectsIn: [player1, player2])

let topPlayers = team.players.filter("jerseyNumber > 10")
```

## What is Realm's Thread-Safe API?

Realm instances are thread-confined by default — you shouldn't pass them between threads. The Thread-Safe API provides:

- **Shared access**: Each thread can safely open its own Realm instance.
- **Atomic transactions**: Each write transaction commits as a single unit.
- **Auto-refresh**: Instances automatically reflect changes from other threads.

```swift
import RealmSwift

let realm = try! Realm()

// Read from any thread
let tasks = realm.objects(Task.self)

// Write from any thread
try! realm.write {
    let newTask = Task()
    newTask.title = "New Task"
    realm.add(newTask)
}
```

## How do you handle migrations in Realm when your data model changes?

1. **Update your model** — add, remove, or rename properties.
2. **Increment the schema version** in your Realm configuration.
3. **Define a migration block** to transform existing data.

```swift
let config = Realm.Configuration(
    schemaVersion: 2,
    migrationBlock: { migration, oldSchemaVersion in
        if oldSchemaVersion < 2 {
            migration.enumerateObjects(ofType: Task.className()) { _, newObject in
                newObject!["newProperty"] = "default value"
            }
        }
    }
)
Realm.Configuration.defaultConfiguration = config
```

4. **Open Realm normally** — migration runs automatically when needed.

```swift
let realm = try Realm()
```

## How does Realm's notification mechanism work?

Realm notifies observers when data changes, making it easy to keep UI in sync.

```swift
import RealmSwift
import SwiftUI

class Task: Object {
    @Persisted var title: String = ""
    @Persisted var isCompleted: Bool = false
}

struct TaskListView: View {
    @ObservedResults(Task.self) var tasks

    var body: some View {
        List(tasks) { task in
            Text(task.title)
                .foregroundColor(task.isCompleted ? .green : .red)
        }
    }
}
```

For manual observation, use `observe` and retain the token:
```swift
let token = tasks.observe { changes in
    switch changes {
    case .initial: tableView.reloadData()
    case .update(_, let deletions, let insertions, let modifications):
        tableView.beginUpdates()
        tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        tableView.endUpdates()
    case .error(let error): fatalError("\(error)")
    }
}
```

## Discuss Realm's write transactions.

All writes (add, modify, delete) must happen inside a write transaction. Transactions are:
- **Atomic**: all changes apply or none do
- **Isolated**: changes aren't visible to other transactions until committed
- **Rollback-safe**: errors automatically cancel the transaction

```swift
let realm = try! Realm()

try! realm.write {
    let newTask = Task()
    newTask.title = "New Task"
    realm.add(newTask)
}
```

Batch multiple related writes in one transaction to minimize commits and improve performance.

## Basic CRUD with Realm

```swift
import RealmSwift

let realm = try! Realm()

class Task: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title = ""
}

// Create
let newTask = Task()
newTask.title = "Complete interview questions"
try! realm.write { realm.add(newTask) }

// Read
let tasks = realm.objects(Task.self)

// Update
if let task = tasks.first {
    try! realm.write { task.title = "Updated title" }
}

// Delete
if let task = tasks.first {
    try! realm.write { realm.delete(task) }
}
```

## How would you optimize Realm performance for large datasets?

- **Index frequently queried properties:**
```swift
class Task: Object {
    @Persisted(indexed: true) var title: String = ""
}
```

- **Filter queries instead of loading all data:**
```swift
let highPriority = realm.objects(Task.self).filter("priority == 'High'")
```

- **Run writes on background threads** to avoid blocking the main thread:
```swift
DispatchQueue.global().async {
    let realm = try! Realm()
    try! realm.write { /* ... */ }
}
```

- **Use lazy loading**: Realm only loads data when accessed, so `realm.objects(Task.self)` is cheap until iterated.

- **Batch operations**: Wrap multiple writes in one transaction.

- **Plan schema migrations carefully**: Use lightweight migrations when possible to avoid expensive data transforms on large datasets.

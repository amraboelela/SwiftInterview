# Database

## Comparison: SwiftData vs Realm vs Core Data

| | SwiftData | Realm | Core Data |
|---|---|---|---|
| Provider | Apple (native) | Third-party (MongoDB) | Apple (native) |
| Storage | SQL (SQLite) | NoSQL (custom engine) | SQL (SQLite) |
| Object-oriented | Yes (`@Model` classes) | Yes (subclass `Object`) | Partial (NSManagedObject) |
| Structs support | No (classes only) | No (classes only) | No (classes only) |
| Min iOS | iOS 17+ | iOS 11+ | iOS 3+ |
| Language | Swift only | Swift + Kotlin | Swift + ObjC |
| API style | Macros + SwiftUI | Subclass + `@Persisted` | NSManagedObject |
| Real-time sync | No (CloudKit) | Yes (Atlas Device Sync) | No |
| Cross-platform | No | Yes (iOS + Android) | No |
| Thread safety | Automatic (actors) | Manual (per-thread instances) | Manual (NSManagedObjectContext) |
| Migration | Auto + VersionedSchema | Manual migration block | Lightweight + heavy |
| Ease of use | Very simple | Simple | Complex |
| SwiftUI integration | Native (`@Query`, `@Environment`) | Good (`@ObservedResults`) | Poor (requires wrappers) |
| Performance | Good | Excellent | Good |
| Maturity | New (2023) | Mature | Very mature |

### Bottom Line
- **New iOS 17+ SwiftUI app** → SwiftData (simplest, fully native)
- **Cross-platform or real-time sync** → Realm (unmatched)
- **Legacy codebase** → Core Data (don't migrate unless necessary)

### Why All Three Require Classes, Not Structs

Persistence frameworks need **reference semantics** — the ability to track a single shared instance across your app and the database. Structs are value types, meaning every assignment creates a copy, making it impossible to:

- **Track identity**: the database needs to know "this object is row #42" — a copied struct loses that link
- **Observe changes**: property wrappers like `@Persisted` and `@Model` use runtime introspection that only works on class instances via Objective-C runtime or Swift's observation system
- **Manage relationships**: two objects pointing to the same related object must literally share the same reference, not independent copies
- **Handle lazy loading**: Realm and Core Data load data on demand by swapping in real values behind a reference — impossible with a copied struct

In short: structs are great for pure data, but persistence requires a living, tracked object in memory that the framework can observe, mutate, and sync with the database.

---

## Core Data

Apple's native framework for managing object graphs and persisting data on Apple platforms. Uses SQLite, XML, or binary stores. Tightly integrated with Interface Builder and supports undo/redo. Largely superseded by SwiftData for new projects.

---

## Realm

A third-party NoSQL database — uses an object-oriented model rather than tables and SQL. Data maps directly to Swift/Kotlin classes, making it natural to use on mobile.

Key features:
- Real-time collaboration via **Atlas Device Sync**: changes propagate instantly to all connected clients with automatic conflict resolution
- Cross-platform (iOS + Android share the same model)
- Fast read/write performance with lazy loading
- Built-in thread safety (each thread opens its own instance)

### Relationships

**To-One:**
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

**To-Many:**
```swift
class Player: Object {
    @Persisted var name: String = ""
    @Persisted var jerseyNumber: Int = 0
}

class Team: Object {
    @Persisted var teamName: String = ""
    let players = List<Player>()
}

// Usage
team.players.append(objectsIn: [player1, player2])
let topPlayers = team.players.filter("jerseyNumber > 10")
```

### CRUD & Write Transactions

All writes must happen inside a write transaction — atomic, isolated, and rollback-safe on error.

```swift
let realm = try! Realm()

// Create
try! realm.write {
    let note = Note()
    note.title = "New Note"
    realm.add(note)
}

// Read
let notes = realm.objects(Note.self)
let highPriority = notes.filter("priority == 'High'")

// Update
if let note = notes.first {
    try! realm.write { note.title = "Updated" }
}

// Delete
if let note = notes.first {
    try! realm.write { realm.delete(note) }
}
```

Batch multiple related writes in one transaction to minimize commits.

### Notifications

```swift
struct NoteListView: View {
    @ObservedResults(Note.self) var notes

    var body: some View {
        List(notes) { note in
            Text(note.title)
                .foregroundColor(note.isCompleted ? .green : .red)
        }
    }
}
```

For UIKit, use `observe` and retain the token:
```swift
let token = notes.observe { changes in
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

### Migrations

```swift
let config = Realm.Configuration(
    schemaVersion: 2,
    migrationBlock: { migration, oldSchemaVersion in
        if oldSchemaVersion < 2 {
            migration.enumerateObjects(ofType: Note.className()) { _, newObject in
                newObject!["newProperty"] = "default value"
            }
        }
    }
)
Realm.Configuration.defaultConfiguration = config
let realm = try Realm() // migration runs automatically
```

### Performance Tips

- **Index** frequently queried properties: `@Persisted(indexed: true) var title: String = ""`
- **Filter early**: `realm.objects(Note.self).filter("priority == 'High'")` — Realm is lazy, only loads what you access
- **Background writes**: open a separate Realm instance per thread via `DispatchQueue.global().async { let realm = try! Realm() }`
- **Batch writes**: wrap multiple operations in one `realm.write { }` block

---

## Querying: SwiftData vs Realm

### Fetch all
```swift
// SwiftData
@Query var notes: [Note]

// Realm
let notes = realm.objects(Note.self)
```

### Filter
```swift
// SwiftData — type-safe #Predicate
@Query(filter: #Predicate<Note> { $0.isCompleted == false }) var notes: [Note]

// Realm — NSPredicate string
let notes = realm.objects(Note.self).filter("isCompleted == false")
```

### Sort
```swift
// SwiftData
@Query(sort: \Note.createdAt, order: .reverse) var notes: [Note]

// Realm
let notes = realm.objects(Note.self).sorted(byKeyPath: "createdAt", ascending: false)
```

### Filter + Sort combined
```swift
// SwiftData
@Query(
    filter: #Predicate<Note> { $0.isCompleted == false },
    sort: \Note.createdAt,
    order: .reverse
) var notes: [Note]

// Realm
let notes = realm.objects(Note.self)
    .filter("isCompleted == false")
    .sorted(byKeyPath: "createdAt", ascending: false)
```

### Search by text
```swift
// SwiftData
@Query(filter: #Predicate<Note> { $0.title.contains("meeting") }) var notes: [Note]

// Realm
let notes = realm.objects(Note.self).filter("title CONTAINS[c] 'meeting'")
```

### Fetch one by id
```swift
// SwiftData — via modelContext
let note = try context.fetch(FetchDescriptor<Note>(
    predicate: #Predicate { $0.id == targetId }
)).first

// Realm
let note = realm.objects(Note.self).filter("id == %@", targetId).first
```

### Key Differences

| | SwiftData | Realm |
|---|---|---|
| Query style | Type-safe `#Predicate` | String-based NSPredicate |
| Compile-time safety | Yes | No (runtime errors) |
| Where query lives | `@Query` property wrapper | Anywhere in code |
| Reactive updates | Automatic (SwiftUI) | Requires `observe` token |

SwiftData's `#Predicate` catches typos at compile time. Realm's string predicates are more flexible but can fail at runtime.

---

## SwiftData

Apple's modern persistence framework (iOS 17+). The `@Model` macro makes any class persistable — no subclassing, no `@Persisted`, no manual schema.

### Model & CRUD

```swift
import SwiftData

@Model
class Note {
    var title: String
    var isCompleted: Bool = false
    var createdAt: Date = Date.now

    init(title: String) { self.title = title }
}
```

```swift
struct NoteListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.createdAt) var notes: [Note]

    var body: some View {
        List {
            ForEach(notes) { note in
                Text(note.title)
            }
            .onDelete { indexSet in
                indexSet.forEach { context.delete(notes[$0]) }
            }
        }
        .toolbar {
            Button("Add") { context.insert(Note(title: "New Note")) }
        }
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { NoteListView() }
            .modelContainer(for: Note.self)
    }
}
```

### Relationships

```swift
@Model
class Team {
    var name: String
    @Relationship(deleteRule: .cascade) var players: [Player] = []
    init(name: String) { self.name = name }
}

@Model
class Player {
    var name: String
    var team: Team?
    init(name: String) { self.name = name }
}
```

### Migrations

Lightweight migrations (adding/removing properties) are handled automatically. For custom logic use `VersionedSchema`:

```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Note.self] }
    @Model class Note { var title: String = "" }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Note.self] }
    @Model class Note { var title: String = ""; var isCompleted: Bool = false }
}

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)]
    }
}
```

---

## Final Verdict: SwiftData vs Realm

| | SwiftData | Realm |
|---|---|---|
| Best for | New iOS 17+ SwiftUI apps | Cross-platform, real-time, or older iOS |
| Query safety | Compile-time (`#Predicate`) | Runtime (string predicates) |
| Boilerplate | Minimal (`@Model` macro) | Low (subclass + `@Persisted`) |
| Real-time sync | No | Yes (Atlas Device Sync) |
| Performance | Good | Excellent |
| Android support | No | Yes |
| Apple's future | Fully backed | Third-party dependency |
| Maturity | Young (2023) | Battle-tested |

### SwiftData wins if:
- Your app is **iOS 17+ only**
- You want **zero boilerplate** and native SwiftUI integration
- You value **compile-time query safety**
- You want long-term alignment with Apple's ecosystem
- You don't need Android or real-time multi-user sync

### Realm wins if:
- You need **iOS 11–16** support
- You need **real-time collaboration** between users
- You need **iOS + Android** with a shared data model
- You need **maximum performance** on large datasets
- You want **battle-tested stability** in production

### The honest answer
For a brand new **iOS-only SwiftUI app in 2024+**, SwiftData is the better choice — it's simpler, safer, and Apple is investing heavily in it. Realm still wins for anything cross-platform, real-time, or where iOS 17+ is not an option. Core Data is only worth keeping if you already have it.

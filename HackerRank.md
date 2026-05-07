# HackerRank Questions

## Q: Which sorting algorithm has the best asymptotic runtime complexity?

Pick ONE option:

- Bubble Sort
- Heap Sort
- Selection Sort
- Insertion Sort

**Answer:** **Heap Sort**

| Algorithm      | Best       | Average    | Worst      |
| -------------- | ---------- | ---------- | ---------- |
| Bubble Sort    | O(n)       | O(n²)      | O(n²)      |
| Heap Sort      | O(n log n) | O(n log n) | O(n log n) |
| Selection Sort | O(n²)      | O(n²)      | O(n²)      |
| Insertion Sort | O(n)       | O(n²)      | O(n²)      |

Heap Sort runs in **O(n log n)** in the average and worst case, while the other three are **O(n²)** on average and worst case. Asymptotically, O(n log n) grows much slower than O(n²), so Heap Sort wins.

**Why Heap Sort is O(n log n):**

- Build a max-heap from the input — O(n)
- Repeatedly extract the max and sift down — each extraction is O(log n), and we do it n times → O(n log n)
- Total: O(n) + O(n log n) = **O(n log n)**

**Why the others are O(n²):**

- Each pass places one element in its final position
- Each pass scans the remaining unsorted portion
- n passes × O(n) work per pass = O(n²)

Note: Insertion Sort and Bubble Sort have a best case of O(n) on already-sorted input, but "asymptotic runtime complexity" without qualification refers to the worst-case (or sometimes average-case) bound — and there Heap Sort still wins.

## Q: Build a SwiftUI cell with text and a button, and add VoiceOver so it announces "Joe Smith, click to view details" when reached, then shows details when tapped.

**Answer:**

Combine the text and button into a single accessibility element so VoiceOver reads them as one phrase, and override the label/hint/traits to control exactly what gets spoken.

```swift
import SwiftUI

struct Person: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let phone: String
}

struct PersonCell: View {
    let person: Person
    @State private var showDetails = false

    var body: some View {
        HStack {
            Text(person.name)
            Spacer()
            Button("View") {
                showDetails = true
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), click to view details")
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(.isStaticText)
        .contentShape(Rectangle())
        .onTapGesture { showDetails = true }
        .sheet(isPresented: $showDetails) {
            PersonDetailsView(person: person)
        }
    }
}

struct PersonDetailsView: View {
    let person: Person

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(person.name).font(.title)
            Text("Email: \(person.email)")
            Text("Phone: \(person.phone)")
            Spacer()
        }
        .padding()
    }
}

struct PeopleListView: View {
    let people = [
        Person(name: "Joe Smith", email: "joe@example.com", phone: "555-0101"),
        Person(name: "Jane Doe",  email: "jane@example.com", phone: "555-0102")
    ]

    var body: some View {
        List(people) { person in
            PersonCell(person: person)
        }
    }
}
```

**Key points:**

- `.accessibilityElement(children: .combine)` merges the `Text` and `Button` into one element, so VoiceOver focuses the whole row at once instead of reading text and button separately.
- `.accessibilityLabel("\(person.name), click to view details")` overrides the spoken text. The comma adds a natural pause.
- `.accessibilityAddTraits(.isButton)` tells VoiceOver this row is tappable, so it appends "button" to the announcement and the user knows a double-tap activates it.
- `.contentShape(Rectangle()) + .onTapGesture` makes the entire row tappable for both sighted users and VoiceOver double-tap, keeping behavior consistent with what VoiceOver announces.
- Use `.accessibilityHint("Double tap to open details")` instead of baking "click to view details" into the label if you want to follow Apple's HIG more strictly — labels describe *what* the element is, hints describe *what happens* on activation.

### `.combine` vs `.ignore` — what's the difference?

If the multiple-choice options include `.accessibilityElement(children: .ignore)`, it can look correct because both `.combine` and `.ignore` produce a **single** VoiceOver element instead of reading the `Text` and `Button` separately. The real difference is what happens to the children's accessibility info:

| Behavior                                       | `.ignore` | `.combine` |
| ---------------------------------------------- | --------- | ---------- |
| Children read separately by VoiceOver?         | No        | No         |
| Parent inherits children's **labels**?         | No        | Yes        |
| Parent inherits children's **traits** (`.isButton`)? | No        | Yes        |
| Parent inherits children's **actions** (button tap)? | **No**    | **Yes**    |

So with `.combine`, the `Button`'s tap action automatically becomes the merged element's activation action — VoiceOver double-tap "just works." With `.ignore`, the `Button`'s action is thrown away; the element is inert unless you manually re-add behavior via `.accessibilityAction { ... }` or `onTapGesture` on the parent, plus `.accessibilityAddTraits(.isButton)` so VoiceOver knows it's tappable.

**Idiomatic answer:** `.combine` — it's the standard pattern for "expose a composite view as one tappable element."

**When `.ignore` is appropriate:** when you're drawing something fully custom (e.g. a `Canvas`) and the children have no meaningful accessibility to merge — you provide everything manually.

### Alternative implementation using `.ignore`

This works, but you must manually re-add the trait and the activation action that `.combine` would have inherited from the `Button`:

```swift
struct PersonCellIgnore: View {
    let person: Person
    @State private var showDetails = false

    var body: some View {
        HStack {
            Text(person.name)
            Spacer()
            Button("View") {
                showDetails = true
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(person.name), click to view details")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            PersonDetailsView(person: person)
        }
    }
}
```

Notice the extra work compared to the `.combine` version:

- `.accessibilityAction { showDetails = true }` is now required — without it, VoiceOver double-tap does nothing because the inner `Button`'s action was discarded.
- `.accessibilityAddTraits(.isButton)` is required — `.ignore` did not inherit the button trait from the child.
- The inner `Button` is effectively dead weight for VoiceOver users; it's only there for sighted/touch users. Some teams replace it with a plain `Text("View")` styled like a button to avoid the redundancy.

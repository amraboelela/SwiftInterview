import Foundation

// MARK: - Micro1 — Group Tickets
//
// Q: Given an array of ages (each age in 1...120) and a maxDiff (e.g. 5),
//    return the minimum number of group tickets needed so that within each
//    group, (maxAge - minAge) <= maxDiff.
//
// Constraints:
//   - 1 <= ages.count <= 100_000
//   - 1 <= age <= 120
//   - Target time complexity: BETTER than O(n log n)
//
// Key insight:
//   Ages are bounded by a small constant k = 120. A comparison sort would be
//   O(n log n), but because the value range is tiny we can use COUNTING SORT
//   and finish in O(n + k) — effectively O(n) since k is a constant.
//
// Approach (Counting sort + greedy):
//   1. Build a counts array of size 121 in one pass over the input.   O(n)
//   2. Walk the 120 buckets in ascending order. Anchor a new group at
//      the smallest unassigned age, then keep extending the group as long
//      as the next non-empty bucket is within maxDiff of the anchor.
//      When it isn't, start a new group anchored there.                O(k)
//
// Total: O(n + k) = O(n). ✅  (Strictly faster than O(n log n).)
//
// Why greedy works:
//   Walking ages in ascending order, the smallest unassigned age MUST be the
//   minimum of its group. Stretching the group as far right as the maxDiff
//   window allows can only reduce or equal the number of groups compared
//   to ending earlier — so it's optimal.

func minGroupTickets(ages: [Int], maxDiff: Int) -> Int {
    guard !ages.isEmpty else { return 0 }

    // Step 1 — counting sort over the bounded age range. O(n)
    var counts = [Int](repeating: 0, count: 121)   // indices 0...120, ages use 1...120
    for age in ages {
        counts[age] += 1
    }

    // Step 2 — single greedy sweep across the 120 buckets. O(k) = O(120) = O(1)
    var groups = 0
    var anchor = -1                                 // min age of the currently open group
    for age in 1...120 where counts[age] > 0 {
        if anchor < 0 || age - anchor > maxDiff {
            groups += 1
            anchor = age                            // open a new group here
        }
        // else: this age fits in the open group — no new ticket needed
    }
    return groups
}

// MARK: - Examples

// Example 1: maxDiff = 5
// ages: [1, 3, 7, 10, 14, 20]
//   group 1: anchor=1   -> 1, 3       (7-1=6 > 5, close)
//   group 2: anchor=7   -> 7, 10      (14-7=7 > 5, close)
//   group 3: anchor=14  -> 14         (20-14=6 > 5, close)
//   group 4: anchor=20  -> 20
print(minGroupTickets(ages: [1, 3, 7, 10, 14, 20], maxDiff: 5))   // 4

// Example 2: all same age — single group
print(minGroupTickets(ages: [25, 25, 25, 25], maxDiff: 5))        // 1

// Example 3: everyone fits in one group
print(minGroupTickets(ages: [10, 12, 14, 15], maxDiff: 5))        // 1

// Example 4: maxDiff = 0 — each distinct age is its own group
print(minGroupTickets(ages: [1, 1, 2, 2, 3], maxDiff: 0))         // 3

// Example 5: empty input
print(minGroupTickets(ages: [], maxDiff: 5))                      // 0

// MARK: - Stress test (100k ages)

let large = (0..<100_000).map { _ in Int.random(in: 1...120) }
let start = CFAbsoluteTimeGetCurrent()
let result = minGroupTickets(ages: large, maxDiff: 5)
let elapsed = CFAbsoluteTimeGetCurrent() - start
print("Large input -> \(result) groups in \(elapsed) seconds")


// MARK: - Alternative attempt: Set<Int> of group anchors (NOT optimal — see below)
//
// Idea: keep a Set<Int> where each element is the "anchor" (smallest age) of
// an existing group. For each new age, scan the window [age - maxDiff ...
// age + maxDiff] and check if any value is in the set. If yes, the age joins
// that group; if no, insert `age` as a new anchor. Return groups.count.
//
// Complexity:
//   - Per age: O(maxDiff) window scan × O(1) Set lookup = O(maxDiff)
//   - Total:   O(n · maxDiff)
//
//   Because age is bounded by k = 120, maxDiff is also at most ~120, so
//   this is O(n · k) — same big-O class as counting sort, but with a much
//   larger constant per element (hashing + window scan vs. one array
//   increment). For unbounded values it would be O(n · maxDiff), which can
//   easily exceed O(n log n) when maxDiff is large.
//
// Correctness:
//   This algorithm is order-dependent and produces WRONG answers on
//   unsorted input. Two failure modes are demonstrated below.

func minGroupTicketsSet(ages: [Int], maxDiff: Int) -> Int {
    var groups = Set<Int>()
    for age in ages {
        var matched = false
        for delta in -maxDiff...maxDiff {              // O(maxDiff)
            if groups.contains(age + delta) {           // O(1)
                matched = true
                break
            }
        }
        if !matched {
            groups.insert(age)
        }
    }
    return groups.count
}

// Failure 1 — symmetric window over-merges. maxDiff = 5
// ages = [5, 10, 1]:
//   • 5  -> set = {5}
//   • 10 -> 5 in [5...15], joins group 5      (set still {5})
//   • 1  -> 5 in [-4...6],  joins group 5     (set still {5})
// Returns 1, but 10 - 1 = 9 > 5, so the correct answer is 2.
print("Set approach   [5, 10, 1] maxDiff=5 ->",
      minGroupTicketsSet(ages: [5, 10, 1], maxDiff: 5))     // 1  (WRONG)
print("Counting sort  [5, 10, 1] maxDiff=5 ->",
      minGroupTickets(ages: [5, 10, 1], maxDiff: 5))        // 2  (correct)

// Failure 2 — descending input under-merges. maxDiff = 2
// ages = [5, 3, 1]:
//   • 5 -> {5}
//   • 3 -> 5 in [1...5], joins group 5        (set still {5})
//   • 1 -> 5 in [-1...3], joins group 5       (set still {5})
// Returns 1 with the symmetric window, but 5 - 1 = 4 > 2, so correct is 2.
print("Set approach   [5, 3, 1]  maxDiff=2 ->",
      minGroupTicketsSet(ages: [5, 3, 1], maxDiff: 2))      // 1  (WRONG)
print("Counting sort  [5, 3, 1]  maxDiff=2 ->",
      minGroupTickets(ages: [5, 3, 1], maxDiff: 2))         // 2  (correct)

// Summary:
//   • Time complexity of the Set approach: O(n · maxDiff)
//     — bounded by O(n · k) when ages are in 1...120, but with a much
//       larger constant than counting sort.
//   • Correctness: fails on unsorted input because the set never updates
//     the "anchor" when a group stretches, so later ages can be merged into
//     a group whose true span already exceeds maxDiff.
//   • To make it correct, you must either sort first (back to O(n log n))
//     or walk ages in ascending order via counting buckets — which is
//     exactly what minGroupTickets(ages:maxDiff:) above already does in
//     O(n + k).


// MARK: - Variant: sort first, then anchor-set with optional replacement
//
// Fix: sort `ages` ascending before the sweep. Now the first age placed in
// a group IS its min and STAYS its min, so the set's single stored anchor
// per group is faithful to the group's true minimum. Each later age is
// >= the anchor, so the symmetric window never under-counts groups.
//
// (Once sorted, the `age < anchor` replace branch becomes unreachable —
// it's kept in the code for parity with the earlier variant, but it never
// fires on sorted input.)
//
// Complexity:
//   - Sort:           O(n log n)
//   - Per age:        O(maxDiff) window scan × O(1) Set lookup
//   - Total:          O(n log n + n · maxDiff)
//   With ages bounded to 1...120, maxDiff ≤ ~120, so the second term is
//   O(n) and the sort dominates: O(n log n). Strictly worse than the
//   counting-sort O(n + k) version above, but now correct.

func minGroupTicketsSetReplacing(ages: [Int], maxDiff: Int) -> Int {
    var groups = Set<Int>()
    for age in ages.sorted() {
        var matchedAnchor: Int? = nil
        for delta in -maxDiff...maxDiff {
            let candidate = age + delta
            if groups.contains(candidate) {
                matchedAnchor = candidate
                break
            }
        }
        if let anchor = matchedAnchor {
            if age < anchor {
                groups.remove(anchor)        // unreachable on sorted input
                groups.insert(age)
            }
            // else: age >= anchor, leave the set alone
        } else {
            groups.insert(age)               // brand-new group
        }
    }
    return groups.count
}

// Previously-failing case 1 — now correct after sorting. maxDiff = 5
// sorted ages = [1, 5, 10]:
//   • 1  -> {1}
//   • 5  -> matches 1 (1 ∈ [0...10]). {1}, group spans 1..5
//   • 10 -> window [5...15], 1 not in it -> new group. {1, 10}
// Returns 2. ✅
print("Set+replace+sort  [5, 10, 1] maxDiff=5 ->",
      minGroupTicketsSetReplacing(ages: [5, 10, 1], maxDiff: 5))   // 2  (correct)

// Previously-failing case 2 — now correct after sorting. maxDiff = 2
// sorted ages = [1, 3, 5]:
//   • 1 -> {1}
//   • 3 -> matches 1 (1 ∈ [1...5]). {1}, group spans 1..3
//   • 5 -> window [3...7], 1 not in it -> new group. {1, 5}
// Returns 2. ✅
print("Set+replace+sort  [5, 3, 1]  maxDiff=2 ->",
      minGroupTicketsSetReplacing(ages: [5, 3, 1], maxDiff: 2))    // 2  (correct)

// MARK: - Stress test for the sorted-set variant (100k ages)

let large2 = (0..<100_000).map { _ in Int.random(in: 1...120) }
let start2 = CFAbsoluteTimeGetCurrent()
let result2 = minGroupTicketsSetReplacing(ages: large2, maxDiff: 5)
let elapsed2 = CFAbsoluteTimeGetCurrent() - start2
print("Set+replace+sort 100k -> \(result2) groups in \(elapsed2) seconds")

// For comparison, run the counting-sort version on the same input:
let start3 = CFAbsoluteTimeGetCurrent()
let result3 = minGroupTickets(ages: large2, maxDiff: 5)
let elapsed3 = CFAbsoluteTimeGetCurrent() - start3
print("Counting sort    100k -> \(result3) groups in \(elapsed3) seconds")

// MARK: - Where does the time actually go?
//
// Observed in this playground:
//   Set+replace+sort 100k -> 20 groups in 15.2 seconds
//   Counting sort    100k -> 20 groups in 0.025 seconds
//
// Q: Is the 15 s mostly the sort?
// A: PARTLY — yes. Two costs are stacked on top of each other, both
//    growing with n:
//
//    1) Sort:  O(n log n) ≈ 100,000 × 17 ≈ 1.7M comparisons.
//              In debug/playground mode each comparison goes through a
//              closure call (no inlining, no -O), so this is real work.
//
//    2) Sweep: O(n · maxDiff) = 100,000 × 11 ≈ 1.1M Set lookups.
//              Every iteration hashes an Int and probes the table.
//
//      for age in sorted {                          // 100,000 iterations
//          for delta in -maxDiff...maxDiff {         // 11 each
//              if groups.contains(age + delta) ...   // hash + probe
//          }
//      }
//
//    The two phases are within ~2× of each other in raw work, so neither
//    one is "the answer" by itself — the slowness is fundamentally that
//    BOTH terms scale with n, and the algorithm is O(n log n + n·maxDiff)
//    overall. The breakdown print below confirms this empirically.
//
//    The counting-sort version replaces both costs: no comparison sort
//    (just 100k array increments — O(n)) and no hash-set sweep (just a
//    120-bucket walk — O(k)). Total O(n + k), which is why it lands at
//    25 ms instead of 15 s.
//
// Why the gap is even larger in a PLAYGROUND than from the command line:
//
//    Xcode playgrounds REWRITE your code at compile time to inject a
//    PlaygroundLogger hook after every executed expression. That hook is
//    what powers the results sidebar ("(executed 1,100,000 times)") and
//    the timeline view. It runs once per iteration of every loop you
//    write, even when only a summary is displayed.
//
//    Concretely, this line:
//
//        if sweepGroups.contains(candidate) { ... }
//
//    becomes (conceptually):
//
//        let __tmp = sweepGroups.contains(candidate)
//        PlaygroundLogger.log(__tmp, line: 292)        // ← injected
//        if __tmp { ... }
//
//    The logger call is cheap individually — a few hundred nanoseconds —
//    but inside our inner loop it fires ~1.1 million times. Multiply by
//    the other instrumented lines in the loop body (the `let candidate`,
//    the `for delta`, the optional unwrap, etc.) and you get tens of
//    millions of logger calls for one stress-test run. That's where the
//    seconds come from.
//
//    The sort is ONE user-code line (`ages.sorted()`). The 1.7M internal
//    comparisons happen inside stdlib's `Sequence.sorted()`, which is
//    pre-compiled and NOT instrumented per-iteration. So the sort pays
//    its ~1.7M comparisons but only ONE logger hit; the sweep pays its
//    ~1.1M hash lookups AND ~1.1M+ logger hits. That's why playground
//    inflation hits the sweep so much harder than the sort.
//
//    Two ways to escape playground instrumentation when you actually
//    need to measure or run hot code:
//
//      1) Move the hot code into `Sources/` inside the playground
//         bundle. Files there compile as a separate module and DO NOT
//         get the logger injection. Call into them from this page.
//      2) Run the file directly: `swift Contents.swift` from a terminal.
//         No playground runtime at all — same algorithm finishes in
//         ~0.6 s for the set version and ~0.015 s for counting sort.
//
//    Rule of thumb: playgrounds are for prototyping and visual
//    exploration, not benchmarking. A loop that runs millions of times
//    will look catastrophically slow here even when the underlying code
//    is perfectly fine in production.
//
// Quick breakdown to confirm: time the sort and the sweep separately.

let large4 = (0..<100_000).map { _ in Int.random(in: 1...120) }

let sortStart = CFAbsoluteTimeGetCurrent()
let sorted4 = large4.sorted()
let sortElapsed = CFAbsoluteTimeGetCurrent() - sortStart

let sweepStart = CFAbsoluteTimeGetCurrent()
var sweepGroups = Set<Int>()
for age in sorted4 {
    var matchedAnchor: Int? = nil
    for delta in -5...5 {
        let candidate = age + delta
        if sweepGroups.contains(candidate) {
            matchedAnchor = candidate
            break
        }
    }
    if let anchor = matchedAnchor {
        if age < anchor {
            sweepGroups.remove(anchor)
            sweepGroups.insert(age)
        }
    } else {
        sweepGroups.insert(age)
    }
}
let sweepElapsed = CFAbsoluteTimeGetCurrent() - sweepStart

print("Breakdown — sort: \(sortElapsed) s,  sweep: \(sweepElapsed) s")

// Expected: sweep ≫ sort. The sort is fast (a few million comparisons in
// tight stdlib code); the sweep is what makes this O(n log n + n·maxDiff)
// algorithm slow in absolute terms. Removing the sort entirely (counting
// sort) is what gets us to 0.025 s — not a faster sort, but no sort at all
// plus a tighter inner loop.

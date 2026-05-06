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


// MARK: - Variant: replace the anchor with the new age if it's smaller
//
// User's refinement: when the new age matches an anchor in the set and the
// new age is smaller than that anchor, remove the old anchor and insert the
// new age — so the set always holds the *smallest* age seen for each group.
//
// Complexity: same as before — O(n · maxDiff). The remove+insert is O(1).
//
// Correctness: still WRONG. Tracking the group's min isn't enough — we also
// need to know the group's MAX, because a small new age can match the
// (now-shrunken) anchor while the group's true max is already too far away.

func minGroupTicketsSetReplacing(ages: [Int], maxDiff: Int) -> Int {
    var groups = Set<Int>()
    for age in ages {
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
                groups.remove(anchor)        // shrink the anchor down to the new min
                groups.insert(age)
            }
            // else: age >= anchor, leave the set alone
        } else {
            groups.insert(age)               // brand-new group
        }
    }
    return groups.count
}

// Same Failure 1 — still wrong even with replacement. maxDiff = 5
// ages = [5, 10, 1]:
//   • 5  -> {5}
//   • 10 -> matches 5; 10 > 5, no replace. {5}     (group really spans 5..10)
//   • 1  -> matches 5; 1 < 5, replace.    {1}     (but group already holds 10!)
// Returns 1, correct is 2 (10 - 1 = 9 > 5).
print("Set+replace   [5, 10, 1] maxDiff=5 ->",
      minGroupTicketsSetReplacing(ages: [5, 10, 1], maxDiff: 5))   // 1  (WRONG)

// Same Failure 2 — still wrong. maxDiff = 2
// ages = [5, 3, 1]:
//   • 5 -> {5}
//   • 3 -> matches 5; 3 < 5, replace.    {3}     (group spans 3..5)
//   • 1 -> matches 3; 1 < 3, replace.    {1}     (but group already holds 5!)
// Returns 1, correct is 2 (5 - 1 = 4 > 2).
print("Set+replace   [5, 3, 1]  maxDiff=2 ->",
      minGroupTicketsSetReplacing(ages: [5, 3, 1], maxDiff: 2))    // 1  (WRONG)

// Why the replace trick doesn't save it:
//   The set stores ONE number per group, but a group is defined by an
//   interval [min, max]. When age 10 joined group 5, the group's max grew
//   to 10 — but the set never recorded that. Later, when age 1 sees anchor
//   5 within its window and replaces it with 1, the group's recorded anchor
//   becomes 1 even though its actual max is still 10. Now max - min = 9,
//   which violates maxDiff = 5, but the algorithm has no way to detect it.
//
//   To make this correct you'd have to track each group's full [min, max]
//   (e.g. a Dictionary<Int, Int> mapping min -> max) AND verify that
//   newMax - newMin <= maxDiff before merging — at which point the data
//   structure is no longer a simple Set, and you've reinvented interval
//   merging. Sorting first (or counting-bucket iteration) sidesteps the
//   whole problem because ages arrive in ascending order, so the first
//   age in a group IS its min and stays that way.

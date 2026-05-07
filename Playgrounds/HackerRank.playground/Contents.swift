import Foundation

// MARK: - HackerRank — Find Number
//
// Q: Given an integer array `arr` and an integer `k`, determine whether `k`
//    appears in the searchable subset of `arr`. Return "YES" if found,
//    otherwise "NO".
//
//    Note: arr[0] is the COUNT of elements to check — the searchable
//    subset is arr[1...arr[0]]. Anything past that index is ignored even
//    if present in the input.
//
// Approach:
//   Read the count from arr[0], then scan exactly that many elements
//   starting at index 1. O(count) time, O(1) space.

func findNumber(arr: [Int], k: Int) -> String {
    guard let count = arr.first, count > 0 else { return "NO" }
    guard count < arr.count else { return "NO" }
    return arr[1...count].contains(k) ? "YES" : "NO"
}

// MARK: - Examples

// arr[0] = 5 → check the next 5 elements: [2, 3, 1, 4, 5]
print(findNumber(arr: [5, 2, 3, 1, 4, 5], k: 4))         // YES
print(findNumber(arr: [5, 2, 3, 1, 4, 5], k: 6))         // NO

// arr[0] = 3 → check ONLY the next 3 elements: [10, 20, 30]
// The trailing 99, 100 are NOT in the searchable subset.
print(findNumber(arr: [3, 10, 20, 30, 99, 100], k: 20))  // YES
print(findNumber(arr: [3, 10, 20, 30, 99, 100], k: 99))  // NO  (out of subset)
print(findNumber(arr: [3, 10, 20, 30, 99, 100], k: 25))  // NO

// MARK: - HackerRank — Odd Numbers
//
// Q: Given two integers l and r (l <= r), return every odd integer in the
//    inclusive range [l, r] in ascending order.
//
// Approach:
//   Bump the start up to the next odd number if l is even, then stride by 2.
//   O((r - l) / 2) time, O(output) space — no per-element parity check.

func oddNumbers(l: Int, r: Int) -> [Int] {
    guard l <= r else { return [] }
    let start = l.isMultiple(of: 2) ? l + 1 : l
    return Array(stride(from: start, through: r, by: 2))
}

// MARK: - Examples

print(oddNumbers(l: 2, r: 5))    // [3, 5]
print(oddNumbers(l: 3, r: 9))    // [3, 5, 7, 9]
print(oddNumbers(l: 4, r: 4))    // []
print(oddNumbers(l: 7, r: 7))    // [7]
print(oddNumbers(l: 5, r: 2))    // []  (invalid range)

// MARK: - HackerRank — Simple Array Sum
//
// Q: Given an integer array, return the sum of its elements.
//
// Approach:
//   `reduce(0, +)` walks the array once, accumulating the running total.
//   O(n) time, O(1) space.
//
// Note: the original draft `ar.reduce(0, i) { $0 + i }` doesn't compile —
// `reduce` takes the initial value and EITHER a combine function or a
// closure, not a free identifier `i`. Either of these works:
//   ar.reduce(0, +)
//   ar.reduce(0) { $0 + $1 }

func simpleArraySum(ar: [Int]) -> Int {
    ar.reduce(0, +)
}

// MARK: - Examples

print(simpleArraySum(ar: [1, 2, 3, 4, 10, 11]))   // 31
print(simpleArraySum(ar: [5]))                    // 5
print(simpleArraySum(ar: []))                     // 0

// MARK: - HackerRank — Compare the Triplets
//
// Q: Alice and Bob each rate three categories on a scale of 1...100.
//    For each index i:
//      • if a[i] > b[i] → Alice gets 1 point
//      • if a[i] < b[i] → Bob gets 1 point
//      • if a[i] == b[i] → neither gets a point
//    Return [aliceScore, bobScore].
//
// Approach:
//   Single pass with `zip` to walk both arrays in lockstep. O(n) time, O(1)
//   extra space (the returned 2-element array).

func compareTriplets(a: [Int], b: [Int]) -> [Int] {
    var alice = 0
    var bob = 0
    for (x, y) in zip(a, b) {
        if x > y { alice += 1 }
        else if x < y { bob += 1 }
    }
    return [alice, bob]
}

// MARK: - Examples

print(compareTriplets(a: [5, 6, 7], b: [3, 6, 10]))    // [1, 1]
print(compareTriplets(a: [17, 28, 30], b: [99, 16, 8])) // [2, 1]
print(compareTriplets(a: [1, 1, 1], b: [1, 1, 1]))     // [0, 0]
print(compareTriplets(a: [10, 10, 10], b: [1, 2, 3]))  // [3, 0]

// MARK: - HackerRank — A Very Big Sum
//
// Q: Given an array of long integers, return the sum. Values can be up to
//    ~10^10 and the array can hold up to 10 elements, so the total can
//    exceed Int32 — but Swift's `Int` is 64-bit on all supported platforms,
//    so plain addition won't overflow for realistic inputs.
//
// Approach:
//   Same as simpleArraySum — `reduce(0, +)`. The "big" in the name is a
//   reminder that other languages need `long`/`int64`; in Swift, `Int` is
//   already 64-bit.

func aVeryBigSum(ar: [Int]) -> Int {
    ar.reduce(0, +)
}

// MARK: - Examples

print(aVeryBigSum(ar: [1000000001, 1000000002, 1000000003, 1000000004, 1000000005]))
// 5000000015
print(aVeryBigSum(ar: [1, 2, 3, 4, 5]))   // 15
print(aVeryBigSum(ar: []))                // 0

// MARK: - HackerRank — Diagonal Difference
//
// Q: Given a square matrix, compute the absolute difference between the
//    sums of its two diagonals.
//      • Primary diagonal:   arr[i][i]
//      • Secondary diagonal: arr[i][n - 1 - i]
//
// Approach:
//   Single pass over the row index. O(n) time, O(1) space.

func diagonalDifference(arr: [[Int]]) -> Int {
    let n = arr.count
    var primary = 0
    var secondary = 0
    for i in 0..<n {
        primary += arr[i][i]
        secondary += arr[i][n - 1 - i]
    }
    return abs(primary - secondary)
}

// MARK: - Examples

// Primary: 11 + 5 + (-12) = 4
// Secondary: 4 + 5 + 10 = 19
// |4 - 19| = 15
print(diagonalDifference(arr: [
    [11,  2,  4],
    [ 4,  5,  6],
    [10,  8, -12]
]))   // 15

// Primary: 1 + 5 + 9 = 15
// Secondary: 3 + 5 + 7 = 15
// |15 - 15| = 0
print(diagonalDifference(arr: [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
]))   // 0

// 1x1 — both diagonals are the same single cell
print(diagonalDifference(arr: [[42]]))   // 0

// MARK: - HackerRank — Plus Minus
//
// Q: Given an integer array, print on three separate lines the ratios of
//    positive, negative, and zero values. Each ratio is printed with 6
//    digits after the decimal point.
//
// Approach:
//   Single pass to count each category. O(n) time, O(1) space.
//   `String(format: "%.6f", ...)` matches HackerRank's expected formatting.

func plusMinus(arr: [Int]) -> Void {
    let n = Double(arr.count)
    var pos = 0, neg = 0, zero = 0
    for x in arr {
        if x > 0 { pos += 1 }
        else if x < 0 { neg += 1 }
        else { zero += 1 }
    }
    print(String(format: "%.6f", Double(pos) / n))
    print(String(format: "%.6f", Double(neg) / n))
    print(String(format: "%.6f", Double(zero) / n))
}

// MARK: - Examples

// 6 elements: 3 positive, 2 negative, 1 zero
// 0.500000 / 0.333333 / 0.166667
plusMinus(arr: [-4, 3, -9, 0, 4, 1])

// 5 elements: 3 positive, 2 negative, 0 zero
// 0.600000 / 0.400000 / 0.000000
plusMinus(arr: [1, 1, 0, -1, -1])

// MARK: - HackerRank — Staircase
//
// Q: Print a right-aligned staircase of height `n`, drawn with `#` and
//    spaces. Row i (1...n) has (n - i) leading spaces and i `#` characters.
//
//    Example for n = 4:
//       #
//      ##
//     ###
//    ####
//
// Approach:
//   For each row, build (n - i) spaces + i hashes via `String(repeating:)`.
//   O(n²) total characters printed, which is the size of the output.

func staircase(n: Int) -> Void {
    for i in 1...n {
        let spaces = String(repeating: " ", count: n - i)
        let hashes = String(repeating: "#", count: i)
        print(spaces + hashes)
    }
}

// MARK: - Examples

staircase(n: 4)
//    #
//   ##
//  ###
// ####

staircase(n: 1)
// #

// MARK: - HackerRank — Mini-Max Sum
//
// Q: Given five positive integers, print the minimum and maximum values
//    obtainable by summing exactly four of them, separated by a space.
//
// Approach:
//   Sum all five. The minimum 4-sum drops the largest element; the maximum
//   4-sum drops the smallest. So:
//     min = total - max
//     max = total - min
//   One pass to compute total/min/max → O(n), O(1) space. Avoids sorting.

func miniMaxSum(arr: [Int]) -> Void {
    guard let first = arr.first else { return }
    var total = 0
    var minV = first
    var maxV = first
    for x in arr {
        total += x
        if x < minV { minV = x }
        if x > maxV { maxV = x }
    }
    print("\(total - maxV) \(total - minV)")
}

// MARK: - Examples

miniMaxSum(arr: [1, 2, 3, 4, 5])           // 10 14
miniMaxSum(arr: [7, 69, 2, 221, 8974])     // 299 9271
miniMaxSum(arr: [5, 5, 5, 5, 5])           // 20 20

// MARK: - HackerRank — Birthday Cake Candles
//
// Q: Only the tallest candles can be blown out. Given an array of candle
//    heights, return how many candles are at the maximum height.
//
// Approach:
//   Single pass: track the running max and a count of how many times we've
//   seen it. Reset the count when a taller candle appears. O(n) time,
//   O(1) space — avoids the two-pass `max() + filter().count` pattern.

func birthdayCakeCandles(candles: [Int]) -> Int {
    var tallest = Int.min
    var count = 0
    for h in candles {
        if h > tallest {
            tallest = h
            count = 1
        } else if h == tallest {
            count += 1
        }
    }
    return count
}

// MARK: - Examples

print(birthdayCakeCandles(candles: [3, 2, 1, 3]))        // 2
print(birthdayCakeCandles(candles: [4, 4, 1, 3]))        // 2
print(birthdayCakeCandles(candles: [1, 2, 3, 4, 5]))     // 1
print(birthdayCakeCandles(candles: [7, 7, 7, 7]))        // 4

// MARK: - HackerRank — Time Conversion
//
// Q: Convert a 12-hour AM/PM time string to 24-hour military format.
//    Input format:  "hh:mm:ssAM" or "hh:mm:ssPM"   (e.g., "07:05:45PM")
//    Output format: "HH:mm:ss"                     (e.g., "19:05:45")
//
// Conversion rules:
//   • 12:xx:xxAM → 00:xx:xx   (midnight rolls hour to 00)
//   • 01..11 AM → hour stays  (no change)
//   • 12:xx:xxPM → 12:xx:xx   (noon stays at 12)
//   • 01..11 PM → hour + 12
//
// Approach:
//   Slice the trailing "AM"/"PM" off, parse the hour, apply the rule,
//   format the hour back to two digits, and reattach "mm:ss".

func timeConversion(s: String) -> String {
    let suffix = s.suffix(2)                       // "AM" or "PM"
    let body = s.dropLast(2)                       // "hh:mm:ss"
    let parts = body.split(separator: ":")
    var hour = Int(parts[0])!
    let minute = parts[1]
    let second = parts[2]

    switch suffix {
    case "AM" where hour == 12: hour = 0
    case "PM" where hour != 12: hour += 12
    default: break
    }
    return String(format: "%02d:%@:%@", hour, String(minute), String(second))
}

// MARK: - Examples

print(timeConversion(s: "07:05:45PM"))   // 19:05:45
print(timeConversion(s: "12:01:00AM"))   // 00:01:00  (midnight)
print(timeConversion(s: "12:01:00PM"))   // 12:01:00  (noon)
print(timeConversion(s: "06:40:03AM"))   // 06:40:03
print(timeConversion(s: "11:59:59PM"))   // 23:59:59

// MARK: - HackerRank — Count Analogy Arrays from Differences
//
// Q: A secret array is hidden — we only know:
//     • differences: an array such that, walking forward from an anchor,
//       each next element equals (current - diff). I.e. the spec defines
//       differences[i] = secret[i] - secret[i + 1]   (note the sign).
//     • lower, upper: every secret[i] must satisfy lower <= secret[i] <= upper
//
//   Return how many integer arrays could be the secret (i.e., how many
//   "analogy" arrays match these differences and stay inside the bounds).
//
// Math (matching the `current -= diff` convention):
//   Pin secret[0] = a. Then secret[k] = a - prefix[k], where
//     prefix[0] = 0
//     prefix[k] = differences[0] + ... + differences[k - 1]   (k >= 1)
//
//   Every position must satisfy lower <= a - prefix[k] <= upper, so
//     lower + prefix[k] <= a <= upper + prefix[k]    for all k
//
//   Intersecting:
//     a_min = lower + max(prefix)
//     a_max = upper + min(prefix)
//
//   Answer = max(0, a_max - a_min + 1)
//          = max(0, upper - lower + min(prefix) - max(prefix) + 1)
//
// Complexity: O(n) time, O(1) extra space.

func numberOfAnalogyArrays(differences: [Int], lower: Int, upper: Int) -> Int {
    var prefix = 0
    var minPrefix = 0      // prefix[0] = 0 is always in play
    var maxPrefix = 0
    for d in differences {
        prefix += d
        if prefix < minPrefix { minPrefix = prefix }
        if prefix > maxPrefix { maxPrefix = prefix }
    }
    return max(0, upper - lower + minPrefix - maxPrefix + 1)
}

// MARK: - Examples

// differences = [1, -3, 4], lower = 1, upper = 6
// prefix = [0, 1, -2, 2] → min = -2, max = 2
// x in [1 - (-2), 6 - 2] = [3, 4] → 2 arrays
//   x=3: [3, 4, 1, 5]
//   x=4: [4, 5, 2, 6]
print(numberOfAnalogyArrays(differences: [1, -3, 4], lower: 1, upper: 6))   // 2

// differences = [3, -4, 5, 1, -2], lower = -4, upper = 5
// prefix = [0, 3, -1, 4, 5, 3] → min = -1, max = 5
// x in [-4 - (-1), 5 - 5] = [-3, 0] → 4 arrays
print(numberOfAnalogyArrays(differences: [3, -4, 5, 1, -2], lower: -4, upper: 5))  // 4

// differences = [4, -7, 2], lower = 3, upper = 6
// prefix = [0, 4, -3, -1] → min = -3, max = 4
// x in [3 - (-3), 6 - 4] = [6, 2] → empty → 0
print(numberOfAnalogyArrays(differences: [4, -7, 2], lower: 3, upper: 6))   // 0

// Empty differences → secret has a single element x in [lower, upper]
print(numberOfAnalogyArrays(differences: [], lower: 1, upper: 5))           // 5

// MARK: - Brute force (for contrast)
//
// Try every candidate anchor in [lower, upper]; walk the diffs; count the
// anchors whose entire secret stays in bounds.
//
// Time:  O((upper - lower + 1) · n)
// Space: O(1)
//
// This works but doesn't scale: if upper - lower is 10^9 and n is 10^5,
// it's 10^14 operations. The closed-form version above is O(n).

func numberOfAnalogyArraysBruteForce(differences: [Int], lower: Int, upper: Int) -> Int {
    var result = 0
    for anchor in lower...upper {
        var current = anchor
        var valid = true
        for diff in differences {
            current -= diff                            // spec convention
            if current < lower || current > upper {
                valid = false
                break
            }
        }
        if valid { result += 1 }
    }
    return result
}

// Sanity-check the brute force agrees with the closed-form on every example.
print(numberOfAnalogyArraysBruteForce(differences: [1, -3, 4], lower: 1, upper: 6))           // 2
print(numberOfAnalogyArraysBruteForce(differences: [3, -4, 5, 1, -2], lower: -4, upper: 5))   // 4
print(numberOfAnalogyArraysBruteForce(differences: [4, -7, 2], lower: 3, upper: 6))           // 0
print(numberOfAnalogyArraysBruteForce(differences: [], lower: 1, upper: 5))                   // 5

// MARK: - HackerRank — Minimum Shade Length Over k Cars
//
// Q: A parking lot has cars at integer spot numbers given by `cars`. Each
//    spot holds at most one car. We want to install a shade — a contiguous
//    range of spots — that covers AT LEAST k of the cars. Return the
//    minimum length of such a shade.
//
//    Length convention: a shade covering spots a...b (inclusive) has
//    length b - a + 1.
//
// Approach (sliding window after sorting):
//   Sort `cars` ascending. Then any minimum-length shade covering k cars
//   spans k *consecutive* cars in the sorted order — never k cars with a
//   skipped car in between (skipping only widens the span).
//
//   So slide a window of size k over the sorted array. For each window
//   [i, i + k - 1], the shade length is:
//       cars[i + k - 1] - cars[i] + 1
//   The answer is the minimum across all windows.
//
// Complexity: O(n log n) for the sort + O(n) for the sweep = O(n log n).

func minShadeLength(cars: [Int], k: Int) -> Int {
    guard k > 0, k <= cars.count else { return 0 }
    let sorted = cars.sorted()
    var best = Int.max
    for i in 0...(sorted.count - k) {
        let span = sorted[i + k - 1] - sorted[i] + 1
        if span < best { best = span }
    }
    return best
}

// MARK: - Examples

// Cars at [2, 10, 8, 17], k = 3
// Sorted: [2, 8, 10, 17]
//   window [2, 8, 10]  → 10 - 2 + 1 = 9
//   window [8, 10, 17] → 17 - 8 + 1 = 10
// Min = 9
print(minShadeLength(cars: [2, 10, 8, 17], k: 3))   // 9

// Cars at [1, 2, 3, 10], k = 2
// Sorted: [1, 2, 3, 10]
//   [1,2]→2, [2,3]→2, [3,10]→8 → min = 2
print(minShadeLength(cars: [1, 2, 3, 10], k: 2))    // 2

// k = 1 → shade only needs to cover one car → length 1
print(minShadeLength(cars: [5, 12, 3, 8], k: 1))    // 1

// k equals the number of cars → shade must span first to last
print(minShadeLength(cars: [4, 1, 9, 6], k: 4))     // 9 (9 - 1 + 1)

// k > number of cars → impossible
print(minShadeLength(cars: [3, 7], k: 5))           // 0

// MARK: - HackerRank — AND Product Over a Range
//
// Q: Given two non-negative integers a and b (a <= b), compute the bitwise
//    AND of every integer in the inclusive range [a, b]:
//        a & (a + 1) & (a + 2) & ... & b
//
// Approach (common-prefix trick):
//   The AND of [a, b] equals the common high-order binary prefix of a and b,
//   padded with zeros. Why: any bit that flips somewhere in the range is
//   ANDed with both a 0 and a 1 at some point, so it ends up 0. Only bits
//   that are identical across every value in the range survive — those are
//   the bits in the shared prefix of a and b.
//
//   Algorithm: shift a and b right in lockstep until they're equal (that's
//   the common prefix), then shift back left by the same amount to restore
//   the place value. O(log b) time, O(1) space — independent of (b - a).
//
//   The naive loop `result = a; for x in (a+1)...b { result &= x }` is
//   O(b - a) and times out when b - a is huge (HackerRank ranges go up to
//   ~2^31).
//
// Edge cases:
//   • a == b   → loop doesn't run, returns a unchanged.
//   • a == 0   → result is 0 (any AND with 0 is 0); the shift loop reaches
//                a == b == 0 and returns 0.

func andProduct(a: Int, b: Int) -> Int {
    var a = a
    var b = b
    var shift = 0
    while a != b {
        a >>= 1
        b >>= 1
        shift += 1
    }
    return a << shift
}

// MARK: - Examples

// 12 = 1100, 13 = 1101, 14 = 1110, 15 = 1111
// 12 & 13 & 14 & 15 = 1100 = 12
print(andProduct(a: 12, b: 15))     // 12

// 5 = 101, 6 = 110, 7 = 111
// 5 & 6 & 7 = 100 = 4
print(andProduct(a: 5, b: 7))       // 4

// Single value → returns itself
print(andProduct(a: 10, b: 10))     // 10

// Crossing a power-of-two boundary forces a high bit to flip → result 0
print(andProduct(a: 7, b: 8))       // 0

// Anything ANDed across a range that includes 0
print(andProduct(a: 0, b: 100))     // 0

// Large range — common-prefix trick handles this in O(log b),
// the naive loop would do ~10^9 iterations
print(andProduct(a: 1_000_000_000, b: 2_000_000_000))   // 0

// MARK: - Brute force (for contrast)
//
// Walk every value in [a, b] and AND it into a running result. Correct, but
// O(b - a) — times out on HackerRank for ranges of ~10^9.
//
// Two pitfalls worth flagging:
//   1. `var result = 1` is WRONG. The identity for bitwise AND is "all bits
//      set" (~0), not 1. Seeding with 1 wipes out every bit except bit 0 on
//      the first iteration, so [12, 15] returns 0 instead of 12.
//   2. Seeding from `a` itself (as below) sidesteps the identity question
//      entirely — start at a, then AND in (a + 1)...b.
//
// Use this only as a reference / sanity check against the O(log b) version.

func andProductBruteForce(a: Int, b: Int) -> Int {
    var result = a
    if a < b {
        for i in (a + 1)...b {
            result &= i
        }
    }
    return result
}

// Sanity-check brute force agrees with the O(log b) version on small inputs.
print(andProductBruteForce(a: 12, b: 15))   // 12
print(andProductBruteForce(a: 5, b: 7))     // 4
print(andProductBruteForce(a: 10, b: 10))   // 10
print(andProductBruteForce(a: 7, b: 8))     // 0
print(andProductBruteForce(a: 0, b: 100))   // 0
// ⚠️ Xcode playgrounds instrument every line for the live results sidebar,
// so they're orders of magnitude slower than compiled Swift. Even 2^24
// (~16M iterations) can hang the playground for a long time. Keep this
// small here; for real benchmarks run as a script:
//
//     swift -O yourfile.swift
//
// Reference numbers from `swift -O` on this machine:
//     [0, 2^23] (~8.4M)   brute force: 0.0009s    shift trick: ~0s
//     [0, 2^30] (~1.07B)  brute force: 0.1365s    shift trick: ~0s
//     [0, 2^32] (~4.3B)   brute force: ~0s*       shift trick: ~0s
//     (* the optimizer eliminates the loop once result == 0)

print(Date())
print(andProductBruteForce(a: 0, b: 1 << 15))
print(Date())

// MARK: - HackerRank — Winning Lottery Ticket
//
// Q: You're given `tickets`, an array of strings made up of the digits 0–9.
//    A pair of tickets (i, j) with i < j is a WINNING pair if, together, the
//    two strings contain every digit 0–9 at least once. Return the number
//    of winning pairs.
//
// Approach (10-bit bitmask + grouping):
//   Each ticket only "matters" through which digits it contains, not how
//   many times or in what order. So encode each ticket as a 10-bit mask
//   (bit d is set if digit d appears). A pair is winning iff
//       mask_i | mask_j == 0b1111111111  (= 1023)
//
//   Naively pairing every two tickets is O(n²) and TLEs when n is large
//   (~10^5). But there are only 2^10 = 1024 distinct masks, so:
//     1) Bucket tickets by mask → counts[mask] = how many tickets have it.
//     2) For each unordered pair of distinct masks (m1, m2) whose OR is
//        1023, add counts[m1] * counts[m2].
//     3) For tickets that already cover all 10 digits on their own
//        (mask == 1023), any two of them form a winning pair → add
//        c * (c - 1) / 2 where c = counts[1023].
//
// Complexity:
//   • Building masks: O(total characters across all tickets)
//   • Pair scan:      O(K²) where K <= 1024 distinct masks → ~10^6 worst
//                     case, independent of n.

func winningLotteryTicket(tickets: [String]) -> Int {
    let allDigits = (1 << 10) - 1            // 1023 — every digit 0...9 present

    var counts = [Int: Int]()
    for ticket in tickets {
        var mask = 0
        for ch in ticket {
            if let d = ch.wholeNumberValue, (0...9).contains(d) {
                mask |= (1 << d)
            }
        }
        counts[mask, default: 0] += 1
    }

    let masks = Array(counts.keys)
    var pairs = 0
    for i in 0..<masks.count {
        for j in i..<masks.count {
            guard (masks[i] | masks[j]) == allDigits else { continue }
            let ci = counts[masks[i]]!
            let cj = counts[masks[j]]!
            if i == j {
                pairs += ci * (ci - 1) / 2   // unordered pairs within the same bucket
            } else {
                pairs += ci * cj
            }
        }
    }
    return pairs
}

// MARK: - Examples

// "129300455"     → digits {0,1,2,3,4,5,9}        → missing 6,7,8
// "5559948277"    → digits {2,4,5,7,8,9}          → missing 0,1,3,6
// "012334556789"  → digits {0,1,2,3,4,5,6,7,8,9}  → all digits
//
// Pairs:
//   (0,1) → missing 6                  → not winning
//   (0,2) → all digits via ticket 2    → winning
//   (1,2) → all digits via ticket 2    → winning
// → 2 winning pairs
print(winningLotteryTicket(tickets: [
    "129300455",
    "5559948277",
    "012334556789"
]))   // 2

// Two complementary tickets that together cover 0...9
//   "01234"  → {0,1,2,3,4}
//   "56789"  → {5,6,7,8,9}
//   union = all → 1 winning pair
print(winningLotteryTicket(tickets: ["01234", "56789"]))   // 1

// Three tickets that ALL individually contain every digit → C(3, 2) = 3 pairs
print(winningLotteryTicket(tickets: [
    "0123456789",
    "9876543210",
    "01234567890123456789"
]))   // 3

// No pair ever covers all 10 digits → 0
print(winningLotteryTicket(tickets: ["111", "222", "333"]))   // 0

// Single ticket — no pair to form
print(winningLotteryTicket(tickets: ["0123456789"]))   // 0


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

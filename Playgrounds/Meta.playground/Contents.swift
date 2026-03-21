// List buildings which can see the sea shore, example, buildings = [4,2,3,1] as shore is at the end of the buildings

//In Swift, to determine which buildings can see the sea shore given that the sea is at the end of the building array, you need to find all buildings that are not blocked by a taller building between them and the sea. In your example with `buildings = [4, 2, 3, 1]`, a building can see the sea if there is no taller building to its right.
//
//Here's how you can implement this in Swift:
//
//1. Traverse the array from right to left (since the sea is at the end).
//2. Keep track of the tallest building seen so far.
//3. If a building is taller than the tallest building seen so far, it can see the sea.
//
//Here's the Swift code for this logic:

func buildingsWithSeaView(buildings: [Int]) -> [Int] {
    var buildingsWithView: [Int] = []
    var currentMaxHeight = 0

    for i in (0..<buildings.count).reversed() {
        if buildings[i] > currentMaxHeight {
            buildingsWithView.append(i)
            currentMaxHeight = buildings[i]
        }
    }

    return buildingsWithView.reversed()
}

let buildings = [4, 2, 3, 1]
let viewBuildings = buildingsWithSeaView(buildings: buildings)
print(viewBuildings)

//In this code:
//
//- We traverse the `buildings` array in reverse order.
//- We maintain a `currentMaxHeight` variable to keep track of the tallest building seen so far.
//- If we encounter a building taller than `currentMaxHeight`, we add it to the `buildingsWithView` array and update `currentMaxHeight`.
//- Finally, we reverse the `buildingsWithView` array to return the result in the original order of the input array.
//
//The output for your example `[4, 2, 3, 1]` would be `[4, 3]` since buildings 4 and 3 are the only ones that can see the sea without being blocked by a taller building in front of them.
                
// Do a cache with capacity and if it hits the capacity then remove the least used item in the list, and using a queue data structure
                                            

// Implementing a cache with a fixed capacity in Swift, where the least recently used (LRU) item is removed when the capacity is hit, typically involves two data structures: a dictionary (for fast access) and a queue (to track usage order). The queue is often implemented using a doubly linked list for efficient removals and insertions.
//
// Here's a basic implementation of an LRU cache in Swift:

class LRUCache<Key: Hashable, Value> {
    private struct CachePayload {
        let key: Key
        let value: Value
    }

    private let capacity: Int
    private var cache = [Key: LinkedListNode<CachePayload>]()
    private var priority = LinkedList<CachePayload>()
    
    init(capacity: Int) {
        self.capacity = max(capacity, 1) // Ensure the capacity is at least 1
    }

    func getValue(for key: Key) -> Value? {
        guard let node = cache[key] else {
            return nil
        }

        priority.moveToHead(node)
        return node.value.value
    }

    func setValue(_ value: Value, for key: Key) {
        let payload = CachePayload(key: key, value: value)

        if let node = cache[key] {
            node.value = payload
            priority.moveToHead(node)
        } else {
            let node = priority.addHead(value: payload)
            cache[key] = node

            if cache.count > capacity {
                if let tail = priority.removeTail() {
                    cache.removeValue(forKey: tail.value.key)
                }
            }
        }
    }
}

class LinkedListNode<T> {
    var value: T
    var next: LinkedListNode?
    weak var previous: LinkedListNode?

    init(value: T) {
        self.value = value
    }
}

class LinkedList<T> {
    private var head: LinkedListNode<T>?
    private var tail: LinkedListNode<T>?

    func addHead(value: T) -> LinkedListNode<T> {
        let newNode = LinkedListNode<T>(value: value)
        if let headNode = head {
            headNode.next = newNode
            newNode.previous = headNode
            head = newNode
        } else {
            head = newNode
            tail = newNode
        }
        return newNode
    }

    func moveToHead(_ node: LinkedListNode<T>) {
        guard node !== head else { return }
        let prev = node.previous
        let next = node.next

        prev?.next = next
        next?.previous = prev

        node.previous = head
        node.next = nil

        if node === tail {
            tail = prev
        }

        head?.next = node
        head = node
    }

    func removeTail() -> LinkedListNode<T>? {
        guard let tailNode = tail else { return nil }
        let next = tailNode.next
        next?.previous = nil
        tail = next

        if head === tailNode {
            head = nil
        }

        return tailNode
    }
}


//In this implementation:
//
//- `LRUCache` maintains a dictionary (`cache`) for fast lookup and a linked list (`priority`) to track the order of use.
//- When an item is accessed or added, it is moved to the head of the linked list, indicating that it was recently used.
//- If adding a new item exceeds the cache's capacity, the least recently used item (at the tail of the linked list) is removed.
//- `LinkedList` and `LinkedListNode` are simple implementations of a doubly linked list to support efficient reordering and removal of nodes.
//
//This cache is generic and can be used with any key-value pair where the key is hashable. The implementation can be extended or modified to suit specific needs or optimizations, such as thread safety in a concurrent environmen

// Give me an example of calling the cache with items

//Certainly! Let's go through an example of how you would use the `LRUCache` class that was defined earlier. In this example, I'll create a cache for storing integers with string keys, add some items to it, retrieve some items, and show how the cache evicts the least recently used item when it reaches its capacity.
//
//Here's how you can use the `LRUCache`:


// Create a cache with a capacity of 3
let cache = LRUCache<String, Int>(capacity: 3)

// Add some items to the cache
cache.setValue(10, for: "Item1")
cache.setValue(20, for: "Item2")
cache.setValue(30, for: "Item3")

// Retrieve an item
if let value = cache.getValue(for: "Item1") {
    print("Retrieved \(value) for Item1")
} else {
    print("Item1 not found in cache")
}

// Add another item, causing the least recently used item ('Item2') to be evicted
cache.setValue(40, for: "Item4")

// Try to retrieve the evicted item
if let value = cache.getValue(for: "Item2") {
    print("Retrieved \(value) for Item2")
} else {
    print("Item2 not found in cache - it was evicted")
}

// Access 'Item3' to mark it as recently used
if let value = cache.getValue(for: "Item3") {
    print("Retrieved \(value) for Item3")
}

// Add one more item, which will evict 'Item1' since 'Item3' was just accessed and 'Item4' is the most recently added
cache.setValue(50, for: "Item5")

// Try to retrieve 'Item1' which is now evicted
if let value = cache.getValue(for: "Item1") {
    print("Retrieved \(value) for Item1")
} else {
    print("Item1 not found in cache - it was evicted")
}


//In this example:
//
//- We first create an `LRUCache` instance with a capacity of 3.
//- We add three items (`Item1`, `Item2`, and `Item3`) to the cache.
//- We retrieve `Item1` to demonstrate accessing an item in the cache.
//- We add `Item4`, which causes the cache to evict the least recently used item (`Item2` at this point).
//- We attempt to retrieve `Item2`, but it's no longer in the cache because it was evicted.
//- We then access `Item3`, making it the most recently used.
//- Finally, we add `Item5`, which causes the cache to evict `Item1` because it is now the least recently used item after `Item3` was accessed.
//
//Running this code would output something like:
//
//```
//Retrieved 10 for Item1
//Item2 not found in cache - it was evicted
//Retrieved 30 for Item3
//Item1 not found in cache - it was evicted
//```
//
//This demonstrates how the `LRUCache` is maintaining the most recently used items up to its capacity and evicting the least recently used ones when new items are added beyond its capacity.
                    

// What if we use queue instead of linked list

// Using a queue for implementing an LRU (Least Recently Used) cache in Swift is possible, but it's important to note that a standard queue (FIFO - First In, First Out) doesn't naturally support the operations needed for an LRU cache, such as moving an accessed item to the back of the queue or efficiently removing items from the middle of the queue.
//
// In an LRU cache, you need to be able to quickly:
//
//1. Add items to the cache.
//2. Retrieve items and mark them as recently used (moving them to the back of the queue).
//3. Remove the least recently used item when the cache is full (the item at the front of the queue).
//4. Potentially remove items from the middle of the queue if they are accessed and moved to the back.
//
// A standard queue doesn't efficiently support the third and fourth operations. However, you can simulate these operations by using a combination of a queue and a hash table (dictionary in Swift), where the queue is used to track the usage order and the hash table is used for fast access to the queue nodes.
//
// Here’s a basic structure of how this might be implemented:

class LRUCacheWithQueue<Key: Hashable, Value> {
    private var cache: [Key: Value] = [:]
    private var usageQueue: [Key] = []
    private let capacity: Int

    init(capacity: Int) {
        self.capacity = max(capacity, 1) // Ensure the capacity is at least 1
    }

    func getValue(for key: Key) -> Value? {
        guard let value = cache[key] else {
            return nil
        }
        // Move key to the back of the queue to mark it as recently used
        moveToBack(key)
        return value
    }

    func setValue(_ value: Value, for key: Key) {
        if cache[key] != nil {
            cache[key] = value
            moveToBack(key)
        } else {
            cache[key] = value
            usageQueue.append(key)
            if usageQueue.count > capacity {
                let leastUsedKey = usageQueue.removeFirst()
                cache.removeValue(forKey: leastUsedKey)
            }
        }
    }

    private func moveToBack(_ key: Key) {
        if let index = usageQueue.firstIndex(of: key) {
            usageQueue.remove(at: index)
        }
        usageQueue.append(key)
    }
}

//In this implementation:
//
//- `cache` is a dictionary that stores the key-value pairs.
//- `usageQueue` is an array that represents a queue to keep track of the usage order of the keys.
//- When an item is accessed or added, it is moved to the back of the `usageQueue` to mark it as recently used.
//- If adding a new item exceeds the cache's capacity, the least recently used item (the item at the front of the `usageQueue`) is removed.
//
// This approach has a drawback in terms of efficiency. The `moveToBack` method has a linear complexity (`O(n)`) because it involves searching for the item in the `usageQueue`. For an LRU cache that handles a large number of items or frequent accesses, using a doubly linked list (as in the previous example) is more efficient due to its `O(1)` complexity for additions, removals, and moving items.

// Create a cache with a capacity of 3
let cacheWithQueue = LRUCacheWithQueue<String, Int>(capacity: 3)

// Add some items to the cache
cacheWithQueue.setValue(10, for: "Item1")
cacheWithQueue.setValue(20, for: "Item2")
cacheWithQueue.setValue(30, for: "Item3")

// Retrieve an item
if let value = cacheWithQueue.getValue(for: "Item1") {
    print("Retrieved \(value) for Item1")
} else {
    print("Item1 not found in cache")
}

// Add another item, causing the least recently used item ('Item2') to be evicted
cacheWithQueue.setValue(40, for: "Item4")

// Try to retrieve the evicted item
if let value = cacheWithQueue.getValue(for: "Item2") {
    print("Retrieved \(value) for Item2")
} else {
    print("Item2 not found in cache - it was evicted")
}

// Access 'Item3' to mark it as recently used
if let value = cacheWithQueue.getValue(for: "Item3") {
    print("Retrieved \(value) for Item3")
}

// Add one more item, which will evict 'Item1' since 'Item3' was just accessed and 'Item4' is the most recently added
cacheWithQueue.setValue(50, for: "Item5")

// Try to retrieve 'Item1' which is now evicted
if let value = cacheWithQueue.getValue(for: "Item1") {
    print("Retrieved \(value) for Item1")
} else {
    print("Item1 not found in cache - it was evicted")
}

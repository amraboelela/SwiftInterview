import Foundation

// Reverse a String

func reverse(string: String) -> String {
    var reversedString = ""
    let array = Array(string)
    //return String(array.reversed())
    for i in (0..<array.count).reversed() {
        reversedString.append(array[i])
    }
    return reversedString
}

let string = "Hello, world!"
let reversedString = reverse(string: string)
print(reversedString) // "!dlrow ,olleH"


// Find the Missing Number

func findMissingNumber(array: [Int]) -> Int {
    let sum = array.reduce(0, +)
    let count = array.count
    let expectedSum = (count * (count + 1)) / 2
    return expectedSum - sum
}

let missingNumberArray = [0, 1, 2, 3, 5]
let missingNumber = findMissingNumber(array: missingNumberArray)
print(missingNumber) // 4


// Two Sum

func twoSum(array: [Int], target: Int) -> [Int]? {
    var dictionary = [Int: Int]()
    for (i, num) in array.enumerated() {
        let complement = target - num
        if let index = dictionary[complement] {
            return [index, i]
        }
        dictionary[num] = i
    }
    return nil
}

let twoSumArray = [1, 2, 7, 11, 15]
let target = 9
let indices = twoSum(array: twoSumArray, target: target)
if let indices = indices {
    print(indices) // [1, 2]
} else {
    print("No such pair exists.")
}


// Palindrome Check

func isPalindrome(string: String) -> Bool {
    var leftPointer = 0
    var rightPointer = string.count - 1
    let array = Array(string)
    while leftPointer < rightPointer {
        if array[leftPointer] != array[rightPointer] {
            return false
        }
        leftPointer += 1
        rightPointer -= 1
    }
    return true
}

func isPalindrome2(string: String) -> Bool {
    return Array(string) == Array(string.reversed())
}

let palindromeString = "racecar"
if isPalindrome(string: palindromeString) {
    print("The string is a palindrome.")
} else {
    print("The string is not a palindrome.")
}
isPalindrome2(string: palindromeString)
isPalindrome2(string: "palindromeString")

// FizzBuzz

func fizzBuzz() {
    for i in 1...100 {
        if i % 3 == 0 && i % 5 == 0 {
            print("FizzBuzz")
        } else if i % 3 == 0 {
            print("Fizz")
        } else if i % 5 == 0 {
            print("Buzz")
        } else {
            print(i)
        }
    }
}

fizzBuzz()


// Linked List Cycle Detection

class Node {
    var next: Node?
    var value: Int

    init(_ value: Int) {
        self.value = value
    }
}

func hasCycle(head: Node?) -> Bool {
    var slow = head
    var fast = head
    while fast != nil && fast?.next != nil {
        slow = slow?.next
        fast = fast?.next?.next
        if slow === fast {
            return true
        }
    }
    return false
}

let head = Node(1)
head.next = Node(2)
head.next?.next = Node(3)
head.next?.next?.next = head
let hasACycle = hasCycle(head: head)
if hasACycle {
    print("The linked list has a cycle.")
} else {
    print("The linked list does not have a cycle.")
}


// Merge Two Sorted Arrays

func merge(array1: [Int], array2: [Int]) -> [Int] {
    var mergedArray = [Int]()

    var i = 0
    var j = 0

    while i < array1.count && j < array2.count {
        if array1[i] < array2[j] {
            mergedArray.append(array1[i])
            i += 1
        } else {
            mergedArray.append(array2[j])
            j += 1
        }
    }

    // Add the remaining elements from the first array.
    while i < array1.count {
        mergedArray.append(array1[i])
        i += 1
    }

    // Add the remaining elements from the second array.
    while j < array2.count {
        mergedArray.append(array2[j])
        j += 1
    }

    return mergedArray
}

let array1 = [1, 3, 5, 7]
let array2 = [2, 4, 6, 8]
let mergedArray = merge(array1: array1, array2: array2)
print(mergedArray) // [1, 2, 3, 4, 5, 6, 7, 8]


// Find the First Non-Repeating Character

func firstNonRepeatingCharacter(string: String) -> Character? {
    var dictionary = [Character: Int]()

    for character in string {
        dictionary[character, default: 0] += 1
    }
    for character in string {
        if dictionary[character] == 1 {
            return character
        }
    }
    return nil
}

let firstNonRepeatingCharacterString = "LEETCODE"
let theFirstNonRepeatingCharacter = firstNonRepeatingCharacter(string: firstNonRepeatingCharacterString)
if let theFirstNonRepeatingCharacter {
    print(theFirstNonRepeatingCharacter) // L
} else {
    print("There is no non-repeating character in the string.")
}


// Longest Substring Without Repeating Characters

func lengthOfLongestSubstring(_ s: String) -> Int {
    var maxLength = 0
    var start = 0
    var charMap = [Character: Int]()
    for (end, char) in s.enumerated() {
        if let lastIndex = charMap[char] {
            start = max(start, lastIndex + 1)
        }
        maxLength = max(maxLength, end - start + 1)
        charMap[char] = end
    }
    return maxLength
}

let longestSubstringString = "abcabcbb"
let maxLength = lengthOfLongestSubstring(longestSubstringString)
print(maxLength) // 3


// Binary Search

func binarySearch(array: [Int], target: Int) -> Int {
    var left = 0
    var right = array.count - 1
    while left <= right {
        let mid = left + (right - left) / 2
        if array[mid] == target {
            return mid
        } else if array[mid] < target {
            left = mid + 1
        } else {
            right = mid - 1
        }
    }
    return -1
}

let binarySearchArray = [1, 3, 5, 7, 9]
let binarySearchTarget = 5
let index = binarySearch(array: binarySearchArray, target: binarySearchTarget)
if index != -1 {
    print("The target value is at index \(index).")
} else {
    print("The target value is not in the array.")
}

// Anagram Detection

func areAnagrams(_ str1: String, _ str2: String) -> Bool {
    // Remove spaces and convert to lowercase for case-insensitive comparison
    let cleanStr1 = str1.lowercased().replacing(" ", with: "")
    let cleanStr2 = str2.lowercased().replacing(" ", with: "")

    // Check if the sorted characters of both strings are equal
    return cleanStr1.sorted() == cleanStr2.sorted()
}

let string1 = "listen"
let string2 = "silent"
if areAnagrams(string1, string2) {
    print("The strings are anagrams.")
} else {
    print("The strings are not anagrams.")
}


// Find the Largest Element in a Binary Tree

class TreeNode {
    var value: Int
    var left: TreeNode?
    var right: TreeNode?

    init(_ value: Int) {
        self.value = value
    }
}

func findLargestElement(_ root: TreeNode?) -> Int? {
    if root == nil {
        return nil // Tree is empty
    }

    // Traverse to the rightmost node
    var current = root
    while current?.right != nil {
        current = current?.right
    }

    return current?.value
}

let root = TreeNode(10)
root.left = TreeNode(5)
root.right = TreeNode(15)
root.left?.left = TreeNode(3)
root.left?.right = TreeNode(8)
root.right?.right = TreeNode(20)

if let largest = findLargestElement(root) {
    print("The largest element in the binary tree is \(largest).")
} else {
    print("The tree is empty.")
}


// Fibonacci sequence

func fibonacci(upTo number: Int) -> [Int] {
    var fibonacciSequence = [Int]()
    
    if number <= 0 {
        return fibonacciSequence
    }
    
    var a = 0
    var b = 1
    
    while a <= number {
        fibonacciSequence.append(a)
        let next = a + b
        a = b
        b = next
    }
    
    return fibonacciSequence
}

print(fibonacci(upTo: 50))

import Foundation

// Reverse a String

func reverse(string: String) -> String {
    var reversedString = ""
    let array = Array(string)
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

let palindromeString = "racecar"
if isPalindrome(string: palindromeString) {
    print("The string is a palindrome.")
} else {
    print("The string is not a palindrome.")
}


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

func generateFibonacciSequence(upTo n: Int) -> [Int] {
    var fibonacciSequence: [Int] = []
    
    if n <= 0 {
        return fibonacciSequence
    }
    
    var a = 0
    var b = 1
    
    while a <= n {
        fibonacciSequence.append(a)
        let next = a + b
        a = b
        b = next
    }
    
    return fibonacciSequence
}

let n = 50
let fibonacciSequence = generateFibonacciSequence(upTo: n)

print("Fibonacci sequence up to \(n):")
print(fibonacciSequence)


// Find mismatches entries

func mismatches(records: [[String]]) -> (Set<String>, Set<String>) {
    var missingExitArray = Set<String>()
    var missingEnterArray = Set<String>()
    var dic = [String: String]()
    for record in records {
        let name = record[0]
        let action = record[1]
        if dic[name] == nil {
            if action == "exit" {
                missingEnterArray.insert(name)
            }
        } else {
            if action == dic[name] {
                if action == "enter" {
                    missingExitArray.insert(name)
                } else {
                    missingEnterArray.insert(name)
                }
            }
        }
        dic[name] = action
    }
    for (name, action) in dic {
        if action == "enter" {
            missingExitArray.insert(name)
        }
        
    }
    return (missingExitArray, missingEnterArray)
}

let records1 = [
    ["Nana", "enter"],
    ["Jone", "enter"],
    ["Doe", "exit"],
    ["Nana", "enter"],
    ["Bilal", "enter"],
    ["Bilal", "exit"],
    ["Bilal", "exit"]
]

var output = mismatches(records: records1)
print("records1 output: \(output)")

// Find Unusual Badge Entries

var badgeTimes: [[String]] = [
  ["Paul", "1355"],
  ["Jennifer", "1910"],
  ["Jose", "835"],
  ["Jose", "830"],
  ["Paul", "1315"],
  ["Chloe", "0"],
  ["Chloe", "1910"],
  ["Jose", "1615"],
  ["Jose", "1640"],
  ["Paul", "1405"],
  ["Jose", "855"],
  ["Jose", "930"],
  ["Jose", "915"],
  ["Jose", "730"],
  ["Jose", "940"],
  ["Jennifer", "1335"],
  ["Jennifer", "730"],
  ["Jose", "1630"],
  ["Jennifer", "5"],
  ["Chloe", "1909"],
  ["Zhang", "1"],
  ["Zhang", "10"],
  ["Zhang", "109"],
  ["Zhang", "110"],
  ["Amos", "1"],
  ["Amos", "2"],
  ["Amos", "400"],
  ["Amos", "500"],
  ["Amos", "503"],
  ["Amos", "504"],
  ["Amos", "601"],
  ["Amos", "602"],
  ["Paul", "1416"],
]

func withinOneHour(time1: String, time2: String) -> Bool {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HHmm"
    
    let time1Date = dateFormatter.date(from: time1)
    let time2Date = dateFormatter.date(from: time2)
    
    if let time1Date = time1Date, let time2Date = time2Date {
        let timeDifference = time2Date.timeIntervalSince(time1Date)
        
        // Convert the time difference to hours.
        let timeDifferenceInHours = timeDifference / 3600
        
        // Return true if the time difference is less than one hour.
        return timeDifferenceInHours <= 1
    } else {
        // If the dates could not be parsed, return false.
        return false
    }
}

print("lessThanOneHour: \(withinOneHour(time1: "0200",time2: "0300"))")

func manyTimes(badgeTimes: [[String]]) -> [String: [String]] {
    var result = [String: [String]]()
    var dic: [String: Array<String>] = [String: Array<String>]()
    for badgeTime in badgeTimes {
        let name = badgeTime[0]
        let time = badgeTime[1]
        if dic[name] == nil {
            dic[name] = [time]
        } else {
            if var times = dic[name] {
                times.append(time)
                dic[name] = times
            }
        }
    }
    for (name, times) in dic {
        var paddedTimes = times.map { timeString in
            let paddedString = String(repeating: "0", count: 4 - timeString.count) + timeString
            return paddedString
        }
        paddedTimes = paddedTimes.sorted()
        print("name: \(name), paddedTimes: \(paddedTimes)")
        var frequentTimes = [String]()
        var longestFrequentTimes = [String]()
        var timeIndex = 0
        var time = ""
        while longestFrequentTimes.count < 3 && timeIndex < paddedTimes.count {
            time = paddedTimes[timeIndex]
            if let firstTime = frequentTimes.first {
                if !withinOneHour(time1: firstTime, time2: time) {
                    if frequentTimes.count > longestFrequentTimes.count {
                        longestFrequentTimes = frequentTimes
                    }
                    frequentTimes.removeFirst()
                }
            }
            frequentTimes.append(time)
            timeIndex += 1
        }
        if let firstTime = frequentTimes.first {
            if withinOneHour(time1: firstTime, time2: time) &&
                frequentTimes.count > longestFrequentTimes.count {
                longestFrequentTimes = frequentTimes
            }
        }
        print("longestFrequentTimes: \(longestFrequentTimes)")
        if longestFrequentTimes.count > 2 {
            var unpaddedTimes = longestFrequentTimes.map { timeString in
                let paddedString = "\(Int(timeString) ?? 0)"
                return paddedString
            }
            result[name] = unpaddedTimes
        }
    }
    return result
}

print(manyTimes(badgeTimes: badgeTimes))


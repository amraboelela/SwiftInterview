import Foundation

// Given an integer array nums of length n >= 3 and an integer target, find three integers in nums such that the sum is closest to the target.

func threeSumClosest(_ nums: [Int], _ target: Int) -> Int {
    let sortedNums = nums.sorted()
    var closestSum = Int.max

    for i in 0..<(sortedNums.count - 2) {
        var left = i + 1
        var right = sortedNums.count - 1
        
        while left < right {
            let currentSum = sortedNums[i] + sortedNums[left] + sortedNums[right]
            if currentSum == target {
                return currentSum // If exact match is found
            }
            
            if abs(currentSum - target) < abs(closestSum - target) {
                closestSum = currentSum
            }
            
            if currentSum < target {
                left += 1
            } else {
                right -= 1
            }
        }
    }
    return closestSum
}

let nums = [-1, 2, 1, -4]
let target = 1

let closestSum = threeSumClosest(nums, target)

print(closestSum) // 2

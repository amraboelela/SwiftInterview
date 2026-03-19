import Foundation

// Find mismatches entries

func mismatches(records: [[String]]) -> (Set<String>, Set<String>) {
    var missingExitArray = Set<String>()
    var missingEnterArray = Set<String>()
    var lastActionDictionary = [String: String]()
    for record in records {
        let name = record[0]
        let action = record[1]
        if lastActionDictionary[name] == nil {
            if action == "exit" {
                missingEnterArray.insert(name)
            }
        } else {
            if action == lastActionDictionary[name] {
                if action == "enter" {
                    missingExitArray.insert(name)
                } else {
                    missingEnterArray.insert(name)
                }
            }
        }
        lastActionDictionary[name] = action
    }
    for (name, action) in lastActionDictionary {
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
    guard let t1 = Int(time1), let t2 = Int(time2) else { return false }
    let t1Minutes = (t1 / 100) * 60 + (t1 % 100)
    let t2Minutes = (t2 / 100) * 60 + (t2 % 100)
    return abs(t2Minutes - t1Minutes) <= 60
}

print("lessThanOneHour: \(withinOneHour(time1: "0200",time2: "0300"))")
print("lessThanOneHour: \(withinOneHour(time1: "0200",time2: "0301"))")

func minutesFrom(timeString: String) -> Int {
    guard let t = Int(timeString) else { return 0 }
    return (t / 100) * 60 + (t % 100)
}

print("minutes: \(minutesFrom(timeString: "0200"))")
print("minutes: \(minutesFrom(timeString: "0301"))")

func timeStringFrom(minutes: Int) -> String {
    let hours = String(minutes / 60)
    let mins = String(minutes % 60)
    let paddedMins = String(repeating: "0", count: 2 - mins.count) + mins
    return hours + paddedMins
}

print("minutes: \(timeStringFrom(minutes: 120))")
print("minutes: \(timeStringFrom(minutes: 181))")

func manyTimes(badgeTimes: [[String]]) -> [String: [String]] {
    var result = [String: [String]]()
    var dic = [String: [Int]]()
    for badgeTime in badgeTimes {
        let name = badgeTime[0]
        let time = minutesFrom(timeString: badgeTime[1])
        dic[name, default: []].append(time)
    }
    for (name, times) in dic {
        let sortedTimes = times.sorted()
        print("name: \(name), sortedTimes: \(sortedTimes)")
        var frequentTimes = [Int]()
        var longestFrequentTimes = [Int]()
        for time in sortedTimes {
            if frequentTimes.count > longestFrequentTimes.count {
                longestFrequentTimes = frequentTimes
            }
            while let firstTime = frequentTimes.first, time - firstTime > 60 {
                frequentTimes.removeFirst()
            }
            frequentTimes.append(time)
        }
        if frequentTimes.count > longestFrequentTimes.count {
            longestFrequentTimes = frequentTimes
        }
        print("longestFrequentTimes: \(longestFrequentTimes)")
        if longestFrequentTimes.count > 2 {
            let unpaddedTimes = longestFrequentTimes.map { timeStringFrom(minutes: $0) }
            result[name] = unpaddedTimes
        }
    }
    return result
}

print(manyTimes(badgeTimes: badgeTimes))


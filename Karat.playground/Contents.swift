import Foundation

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


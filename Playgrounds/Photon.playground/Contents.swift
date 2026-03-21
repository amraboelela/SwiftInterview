import Foundation

// "newyorkcitynewyorkcitynewyorkcitycitynewyorkcitycitycitynewyorkcity"
// find how many time "newyork" appears

let text = "newyorkcitynewyorkcitynewyorkcitycitynewyorkcitycitycitynewyorkcity"
let token = "newyork"
let components = text.components(separatedBy: token)
print(components)
let occurrences = components.count - 1

print("The token '\(token)' appears \(occurrences) times.")

// Or

var tokenCount = 0
var index = text.startIndex

while let range = text.range(of: token, range: index..<text.endIndex) {
    tokenCount += 1
    index = range.upperBound
}

print("The token '\(token)' appears \(tokenCount) times.")

// Or

let textArray = Array(text)
tokenCount = 0
for i in 0...(textArray.count - token.count) {
    if String(textArray[i..<(i + token.count)]) == token {
        tokenCount += 1
    }
}

print("The token '\(token)' appears \(tokenCount) times.")


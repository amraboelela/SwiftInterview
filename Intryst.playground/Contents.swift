import Foundation

// Make a function to check the most frequent character in a non-empty string

func mostFrequentCharacter(in text: String) -> Character? {
    // Dictionary to store character frequencies
    var frequencies: [Character: Int] = [:]

    // Iterate over each character in the string
    for char in text {
        // Increment the frequency count for this character
        frequencies[char, default: 0] += 1
    }

    // Find the character with the highest frequency
    var mostFrequentChar: Character?
    var highestFrequency = 0
    for (char, frequency) in frequencies {
        if frequency > highestFrequency {
            mostFrequentChar = char
            highestFrequency = frequency
        }
    }

    return mostFrequentChar
}

func mostFrequentCharacter2(in text: String) -> Character? {
    // Dictionary to store character frequencies
    var frequencies: [Character: Int] = [:]

    // Variables to keep track of the most frequent character
    var mostFrequentChar: Character?
    var highestFrequency = 0

    // Iterate over each character in the string
    for char in text {
        // Increment the frequency count for this character
        frequencies[char, default: 0] += 1

        // Check if this character has a higher frequency than the current most frequent character
        if let frequency = frequencies[char], frequency > highestFrequency {
            mostFrequentChar = char
            highestFrequency = frequency
        }
    }

    return mostFrequentChar
}

func mostFrequentCharacter3(in text: String) -> Character? {
    // Dictionary to store character frequencies
    guard let firstChar = text.first else {
        return nil
    }
    var frequencies: [Character: Int] = [:]

    // Variables to keep track of the most frequent character
    var result = firstChar
    // Iterate over each character in the string
    for char in text {
        // Increment the frequency count for this character
        frequencies[char, default: 0] += 1

        // Check if this character has a higher frequency than the current most frequent character
        if let frequency = frequencies[char],
            let resultFreq = frequencies[result],
            resultFreq < frequency {
            result = char
        }
    }

    return result
}

// Example usage:
let text = "hello world"
if let mostFrequentChar = mostFrequentCharacter3(in: text) {
    print("The most frequent character is '\(mostFrequentChar)'")
} else {
    print("The string is empty")
}

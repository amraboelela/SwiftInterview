
// Given a string that may contain punctuation (!, '), find:
// 1. The number of unique words (case insensitive)
// 2. The most repeated word

func analyzeWords(in text: String) -> (uniqueCount: Int, mostRepeated: String?) {
    let punctuation: Set<Character> = ["!", "'", ",", ".", "?", ";", ":"]

    let cleaned = String(text.map { punctuation.contains($0) ? " " : $0 })
    let tokens = cleaned.lowercased().split(separator: " ")

    var frequency: [String: Int] = [:]
    var mostRepeated: String?
    var maxCount = 0

    for word in tokens {
        let w = String(word)
        frequency[w, default: 0] += 1
        if let count = frequency[w], count > maxCount {
            maxCount = count
            mostRepeated = w
        }
    }

    return (frequency.count, mostRepeated)
}

// Test
let message = "Hello, happy Friday! I hope you will say hello back! This is your interview, and I’m your interviewer. My favorite day of the week is Friday, I’m so glad it’s Friday today."
let result = analyzeWords(in: message)
print("Unique word count: \(result.uniqueCount)")
print("Most repeated word: \(result.mostRepeated ?? "none")")

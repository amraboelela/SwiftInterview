
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
let text = "Hello world! Hello, Swift. swift is great, isn't it? World world!"
let result = analyzeWords(in: text)
print("Unique word count: \(result.uniqueCount)")
print("Most repeated word: \(result.mostRepeated ?? "none")")

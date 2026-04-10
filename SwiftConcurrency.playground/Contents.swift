import Foundation

// MARK: - Download Progress via AsyncStream

func downloadProgress(from url: URL) -> AsyncStream<Int> {
    AsyncStream { continuation in
        Task {
            do {
                let (bytes, response) = try await URLSession.shared.bytes(from: url)
                let total = response.expectedContentLength  // -1 if unknown
                var received: Int64 = 0
                for try await line in bytes.lines {
                    received += Int64(line.utf8.count + 1)  // +1 to account for the newline byte stripped by .lines
                    guard total > 0 else { continue }
                    continuation.yield(min(Int(received * 100 / total), 99))
                }
                continuation.yield(100)
                continuation.finish()
            } catch {
                print("Download error: \(error)")
                continuation.finish()
            }
        }
    }
}

// Test with a small public file
let url = URL(string: "https://www.apple.com/robots.txt")!

Task {
    for await percent in downloadProgress(from: url) {
        print("Progress: \(percent)%")
    }
    print("Done")
}

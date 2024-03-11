import Foundation

let url = URL(string: "https://example.com")!
var message = "Loading..."

Task {
    do {
        var receivedLines = [String]()
        for try await line in url.lines {
            receivedLines.append(line)
            message = "Received \(receivedLines.count) lines"
            print("message: \(message)")
        }
        print("receivedLines: \(receivedLines)")
    } catch {
        message = "Failed to load"
    }
}

print("message: \(message)")

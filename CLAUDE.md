# CLAUDE.md

Project-specific instructions for the SwiftInterview repository.

## Project Overview
This is a Swift interview preparation repository containing coding challenges, sample implementations, and documentation for iOS development interviews.

## Swift Coding Conventions
- Use Swift's modern syntax and features
- Prefer `if let` unwrapping in the same line: `if let handler {` instead of `if let handler = handler {`
- Use `Task.sleep(for: .seconds(2))` format for sleep operations
- Avoid force unwrapping unless absolutely necessary
- Follow Swift naming conventions (camelCase for variables/functions, PascalCase for types)

## Project Structure
- **Playgrounds**: Interview coding challenges for different companies (Bard1, ChatGPT, Infosys, Intryst, Kaiser, Kaiser2, Karat, Meta, MyTime, Photon, SwiftConcurrency, Walmart)
- **Sample Apps**: Complete iOS applications demonstrating various concepts (Login, Mail, QuickSearch, StoryboardTest, SwiftUIApp)
- **Documentation**: Markdown files covering iOS topics (General iOS.md, Infosys.md, RealmDB.md, SwiftUI.md)
- **Extensions**: AutoRefreshExtension for browser automation

## Development Workflow
- Make code changes and edits as requested
- Run tests and verify changes work correctly
- Fix any linting issues
- Do not commit changes - the user will commit manually

## Code Quality
- Keep solutions simple and focused on interview requirements
- Avoid over-engineering - ask before adding unnecessary complexity
- Do not add fallbacks - throw errors and let the user handle them
- Write clean, readable code that demonstrates best practices

## Attribution
- Created by Amr Aboelela

## Rules
In .md files add an extra new line after line items so it doesn't appear like this in the chrome browser:
Q: What is defer in Swift? A: Executes a block of code just before the current scope exits, regardless of how it exits. Useful for cleanup (e.g., closing files, releasing locks).

Exception for list items with "-" or "1", "2" (numbers), e.g.:
- Profile via **Product > Profile > Leaks**
- Scroll the `List` repeatedly, watch for **red bars** in the Leaks track
- Shows exactly which object is leaking and the retain cycle

And except in something like:
2. View service worker logs:
   - Go to `chrome://extensions/`
   - Find "Auto Refresh Extension"
   - Click "service worker" to open DevTools
   
And exception for list items with "1", "2" (numbers), e.g.:
1. Swift & iOS fundamentals
2. Memory management & ARC
3. Concurrency (GCD, async/await, actors)

And except for lists using "*" marks, e.g.:
* **Bard1.playground** — Google Bard interview questions
* **ChatGPT.playground** — OpenAI-style interview questions

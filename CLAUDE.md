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
- **Playgrounds**: Interview coding challenges for different companies (Bard1, ChatGPT, InfoSys, Intryst, Kaiser, Karat, Meta, MyTime, Photon, Walmart)
- **Sample Apps**: Complete iOS applications demonstrating various concepts (Login, Mail, QuickSearch, StoryboardTest, SwiftUIApp)
- **Documentation**: Markdown files covering iOS topics (General iOS.md, InfoSys.md, RealmDB.md, SwiftUI.md)
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

# Repository Guidelines

## Project Structure & Module Organization
The Swift package root tracks dependencies in `Package.swift` and pins versions in `Package.resolved`. Runtime code lives under `Sources/EvalSwiftUI`: `Core` wires up the evaluator, `Builder` constructs view nodes, `IR` defines intermediate data, and `EvalSwiftUI.swift` exposes the public entry points. Tests reside in `Tests/EvalSwiftUITests`, mirroring the runtime modules. Keep fixtures lightweight; large SwiftUI snippets belong beside the test that uses them.

## Build, Test, and Development Commands
- `swift build` — default debug build; add `-c release` before publishing binaries.
- `swift test` — runs the `@Test` suites in `EvalSwiftUITests`.
- `swift test --filter SwiftUIEvaluatorSuccessTests/rendersTextLiteral` — scope runs while iterating on a scenario.
- `swift package resolve` — refreshes dependency pins when upgrading `swift-syntax`.
Use `swift build --target EvalSwiftUI` when validating individual modules, and run commands from the repo root to keep derived data tidy.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines: PascalCase types/protocols, camelCase functions and variables, `SCREAMING_SNAKE_CASE` only for private test fixtures. Indent with four spaces, keep imports sorted (standard, Apple, third-party). Favor `final` classes, mark throwing APIs explicitly, and prefer expressive enum cases (`.missingRootExpression`). Public APIs should include concise doc comments explaining inputs/outputs.

## Testing Guidelines
Tests use the `swift-testing` framework (`import Testing`, `@Test`). Name functions after behavior (`rendersTextLiteral`) and keep assertions close to setup. When adding evaluators or modifiers, include both success and error coverage in `SwiftUIEvaluatorSuccessTests` and `SwiftUIEvaluatorErrorTests`. Run `swift test --enable-code-coverage` before submitting and keep coverage for touched files around 90% by adding targeted scenarios.

## Commit & Pull Request Guidelines
Commits are short, imperative statements (e.g., "Support variable statement"), scoped to one logical change. Reference issues in the body (`Refs #123`) when applicable. Pull requests should describe the SwiftUI scenario being enabled, outline the testing performed (`swift test`, coverage runs), and include screenshots or rendered source snippets if UI behavior changes. Ensure CI remains green before requesting review.

## Security & Configuration Tips
Do not commit sample code that embeds credentials or private bundle identifiers. When reproducing SwiftUI snippets that talk to remote services, stub them or gate them behind compiler flags. Keep `Package.resolved` in sync so reviewers can audit any dependency bumps quickly.

# EvalSwiftUI

EvalSwiftUI is a lightweight Swift package that parses SwiftUI source strings at runtime, builds a typed intermediate representation, and renders the resulting views. The design focuses on extensibility (via registries for builders/modifiers) and high test coverage to make iterative SwiftUI experiments safe.

## Getting Started

### Adding the Package

Add the dependency to your `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    // ...
    dependencies: [
        .package(url: "https://github.com/lkzhao/EvalSwiftUI.git", branch: "main")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "EvalSwiftUI", package: "EvalSwiftUI")
            ]
        )
    ]
)
```

Then resolve and build:

```sh
swift package resolve
swift build
```

The project targets macOS 13 / iOS 16 and later so that `ImageRenderer` is always available for testing utilities.

### Runtime Usage

```swift
import EvalSwiftUI
import SwiftUI

let source = """
VStack {
    Text("Hello, runtime SwiftUI!")
        .font(.title)
    Image(systemName: "globe")
        .imageScale(.large)
}
"""

do {
    let anyView = try evalSwiftUI(source)
    // embed `anyView` inside your SwiftUI hierarchy
} catch {
    print("Failed to evaluate SwiftUI: \(error)")
}
```

## Running Tests

```sh
swift test
```

The test suite uses `swift-testing` macros. Snapshot coverage is driven by the `#expectSnapshot` macro, which renders the given SwiftUI tree, feeds its textual description back through `evalSwiftUI`, and compares the resulting bitmaps.

## Key Components

- `Sources/EvalSwiftUI/Core` – Evaluator entry points, registries, and error definitions.
- `Sources/EvalSwiftUI/IR` – Intermediate view/modifier nodes and expression scopes.
- `Sources/EvalSwiftUI/Builder` – Concrete view and modifier builders plus utilities such as `ViewContent`.
- `Sources/EvalSwiftUIMacros` – The `#expectSnapshot` macro expansion used in tests.
- `Tests/EvalSwiftUITests` – Success, error, and snapshot regression suites.

## Snapshot Testing Macro

Use `#expectSnapshot` inside tests to ensure a SwiftUI snippet matches the evaluator output:

```swift
@Test func rendersStyledText() throws {
    #expectSnapshot(
        Text("Hello, EvalSwiftUI!")
            .font(.headline)
            .padding(12)
    )
}
```

The macro emits the evaluator source, invokes `assertSnapshotsMatch`, and surfaces mismatches through `#expect`.

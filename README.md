# EvalSwiftUI

EvalSwiftUI is a lightweight Swift package that parses SwiftUI source strings at runtime, builds a typed intermediate representation, and renders the resulting views.

## Language Scope

EvalSwiftUI intentionally implements a simplified SwiftUI-like language. It interprets a subset of Swift syntax (expressions, closures, inline `struct View` declarations, and basic state) and only knows about a curated set of view constructors and modifiers. Advanced Swift features—such as generics, result builders, async/await, custom property wrappers, or the full SwiftUI runtime—are out of scope unless you provide custom builders through the registries. 

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

### Stateful snippets and inline views

`@State` works the same way it does in native SwiftUI. You can keep everything inline or even declare `struct` views directly in the snippet:

```swift
let counterSource = """
@State var count: Int = 0
VStack(spacing: 12) {
    Text("Count: \\(count)")
    Button("Increase") {
        count += 1
    }
}
"""

let counterView = try evalSwiftUI(counterSource)

let structSource = """
struct CountView: View {
    @State var count: Int = 0

    var body: some View {
        VStack {
            Text("Count: \\(count)")
            Button("Increase") {
                count += 1
            }
        }
    }
}

struct ContainerView: View {
    var body: some View {
        CountView()
        CountView()
    }
}

ContainerView()
"""

let containerView = try evalSwiftUI(structSource)
```

### Custom Views via Builders

You can expose domain-specific views by registering your own `SwiftUIViewBuilder`:

```swift
import EvalSwiftUI
import SwiftUI

struct Badge: View {
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag")
                .imageScale(.small)
            Text(label)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.2))
        .clipShape(Capsule())
    }
}

struct BadgeViewBuilder: SwiftUIViewBuilder {
    let name = "Badge"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let first = arguments.first, case let .string(label) = first.value else {
            throw SwiftUIEvaluatorError.invalidArguments("Badge expects a string label.")
        }

        return AnyView(Badge(label: label))
    }
}

let evaluator = SwiftUIEvaluator(viewBuilders: [BadgeViewBuilder()])
let badge = try evaluator.evaluate(source: "Badge(\"Beta\")")
```

This mirrors the `rendersCustomViewUsingBuilder` test, ensuring the documentation stays backed by executable coverage.

## Running Tests

```sh
swift test
```

The test suite uses `swift-testing` macros. Snapshot coverage is driven by the `#expectSnapshot` macro, which renders the given SwiftUI tree, feeds its textual description back through `evalSwiftUI`, and compares the resulting bitmaps.

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

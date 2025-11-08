# EvalSwiftUI

EvalSwiftUI is a lightweight Swift package that parses SwiftUI source strings at runtime, builds a typed intermediate representation, and renders the resulting views. The design focuses on extensibility (via registries for builders/modifiers) and high test coverage to make iterative SwiftUI experiments safe.

## Language Scope

EvalSwiftUI intentionally implements a simplified SwiftUI-like language. It interprets a subset of Swift syntax (expressions, closures, inline `struct View` declarations, and basic state) and only knows about a curated set of view constructors and modifiers. Advanced Swift features—such as generics, result builders, async/await, custom property wrappers, or the full SwiftUI runtime—are out of scope unless you provide custom builders through the registries. Keep this in mind when pasting SwiftUI samples: if a construct is missing from the lists below, you will need to stub or rework it before evaluation will succeed.

### Built-in View Constructors

The default `ViewRegistry` wires up the following view builders (see `Sources/EvalSwiftUI/Core/ViewRegistry.swift`):

- `Text`
- `VStack`
- `HStack`
- `ZStack`
- `Spacer`
- `Image`
- `ForEach`
- `Button`
- `Toggle`
- `ScrollView`
- `Rectangle`
- `RoundedRectangle`
- `Circle`

### Built-in Modifiers

Likewise, the `ModifierRegistry` (implemented in `Sources/EvalSwiftUI/Core/ModifierRegistry.swift`) exposes these modifiers out of the box:

- `font(_:)`
- `padding(_:)`
- `imageScale(_:)`
- `foregroundStyle(_:)`
- `frame(...)`
- `background(_:)`
- `overlay(_:)`
- `cornerRadius(_:)`
- `opacity(_:)`
- `shadow(...)`

You can extend either registry by supplying additional builders to `SwiftUIEvaluator` if your use case requires more of the SwiftUI surface area.

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

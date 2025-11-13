import SwiftUI
import Testing
@testable import EvalSwiftRuntime

@MainActor
struct RuntimeSnapshotTests {
    @Test func rendersTopLevelVStackExpression() throws {
        let source = """
        VStack {
            Text("Hello world!")
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Hello world!")
            }
        }
    }

    @Test func rendersInterpolatedTextLiteral() throws {
        let source = """
        struct GreetingView: View {
            var name: String = "World"

            var body: some View {
                Text("Hello, \\(name)!")
            }
        }

        GreetingView()
        """

        try assertSnapshotsMatch(source: source) {
            Text("Hello, World!")
        }
    }

    @Test func rendersStatefulCountView() throws {
        let source = """
        struct CountView: View {
            @State var count: Int = 0

            var body: some View {
                VStack(spacing: 4) {
                    Text("Count: \\(count)")
                    Button("Increase") {
                        count = count + 1
                    }
                }
            }
        }

        CountView()
        """

        try assertSnapshotsMatch(source: source) {
            VStack(spacing: 4) {
                Text("Count: 0")
                Button("Increase") {}
            }
        }
    }

    @Test func wrapsMultipleTopLevelViewsInVStack() throws {
        let source = """
        Text("First")
        Text("Second")
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("First")
                Text("Second")
            }
        }
    }

    @Test func rendersTopLevelStructInvocation() throws {
        let source = """
        struct CountView: View {
            var count: Int = 0

            var body: some View {
                VStack(spacing: 4) {
                    Text("Count: \\(count)")
                }
            }
        }

        CountView()
        """

        try assertSnapshotsMatch(source: source) {
            VStack(spacing: 4) {
                Text("Count: 0")
            }
        }
    }

    @Test func rendersTextSnapshotMatchesExpectedView() throws {
        let source = """
        Text("Runtime Snapshot")
        """

        try assertSnapshotsMatch(source: source) {
            Text("Runtime Snapshot")
        }
    }

    @Test func rendersViewDefinitionWithStoredProperty() throws {
        let source = """
        struct GreetingView: View {
            var message: String = "Hello Runtime"

            var body: some View {
                Text(message)
            }
        }
        """

        try assertSnapshotsMatch(source: source, viewName: "GreetingView") {
            Text("Hello Runtime")
        }
    }

    @Test func rendersVStackCollectingChildText() throws {
        let source = """
        struct StackView: View {
            var body: some View {
                VStack(spacing: 6) {
                    Text("First")
                    Text("Second")
                }
            }
        }
        """

        try assertSnapshotsMatch(source: source, viewName: "StackView") {
            VStack(spacing: 6) {
                Text("First")
                Text("Second")
            }
        }
    }

    @Test func rendersVStackSpacingArgument() throws {
        let source = """
        struct SpacingView: View {
            var body: some View {
                VStack(spacing: 16) {
                    Text("Top")
                    Text("Bottom")
                }
            }
        }
        """

        try assertSnapshotsMatch(source: source, viewName: "SpacingView") {
            VStack(spacing: 16) {
                Text("Top")
                Text("Bottom")
            }
        }
    }

    @Test func rendersHStackSpacingArgument() throws {
        let source = """
        struct RowView: View {
            var body: some View {
                HStack(spacing: 12) {
                    Text("Leading")
                    Text("Trailing")
                }
            }
        }

        RowView()
        """

        try assertSnapshotsMatch(source: source) {
            HStack(spacing: 12) {
                Text("Leading")
                Text("Trailing")
            }
        }
    }

    @Test func rendersNestedVStacks() throws {
        let source = """
        struct NestedStackView: View {
            var body: some View {
                VStack(spacing: 8) {
                    Text("Header")
                    VStack(spacing: 4) {
                        Text("Row 1")
                        Text("Row 2")
                    }
                }
            }
        }
        """

        try assertSnapshotsMatch(source: source, viewName: "NestedStackView") {
            VStack(spacing: 8) {
                Text("Header")
                VStack(spacing: 4) {
                    Text("Row 1")
                    Text("Row 2")
                }
            }
        }
    }

    @Test func rendersViewReturnedFromGlobalFunction() throws {
        let source = """
        var globalText: String = ""

        func globalFunction(value: Int) -> Int {
            return value
        }

        func globalFunctionProducingView(value: Int) -> some View {
            Text("value is \\(value)")
        }

        globalFunctionProducingView(value: globalFunction(value: 5))
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("value is 5")
            }
        }
    }

    @Test func rendersImageSystemSymbol() throws {
        let source = """
        Image(systemName: "globe")
        """

        try assertSnapshotsMatch(source: source) {
            Image(systemName: "globe")
        }
    }

    @Test func rendersForEachOverRange() throws {
        let source = """
        struct RangeList: View {
            var body: some View {
                VStack {
                    ForEach(0..<3) { index in
                        Text("Row \\(index)")
                    }
                }
            }
        }
        """

        try assertSnapshotsMatch(source: source, viewName: "RangeList") {
            VStack {
                Text("Row 0")
                Text("Row 1")
                Text("Row 2")
            }
        }
    }

    @Test func rendersForEachWithExplicitID() throws {
        let source = """
        struct ExplicitIDList: View {
            let items = ["Alpha", "Beta", "Gamma"]

            var body: some View {
                VStack {
                    ForEach(items, id: \\.self) { item in
                        Text(item)
                    }
                }
            }
        }
        """

        try assertSnapshotsMatch(source: source, viewName: "ExplicitIDList") {
            VStack {
                Text("Alpha")
                Text("Beta")
                Text("Gamma")
            }
        }
    }

    @Test func rendersForEachUsingShorthandParameters() throws {
        let source = """
        struct ShorthandList: View {
            var body: some View {
                VStack {
                    ForEach(0..<2) {
                        Text("Value \\($0)")
                    }
                }
            }
        }
        """

        try assertSnapshotsMatch(source: source, viewName: "ShorthandList") {
            VStack {
                Text("Value 0")
                Text("Value 1")
            }
        }
    }

    @Test func rendersForEachUsingNestedShorthandParameters() throws {
        let source = """
        struct ShorthandList: View {
            var body: some View {
                VStack {
                    ForEach(0..<2) {
                        VStack {
                            Text("Value \\($0)")
                        }
                    }
                }
            }
        }
        """

        try assertSnapshotsMatch(source: source, viewName: "ShorthandList") {
            VStack {
                Text("Value 0")
                Text("Value 1")
            }
        }
    }

    @Test func stateMutationTriggersViewRerender() throws {
        let source = """
        struct CounterView: View {
            var count: Int = 0

            var body: some View {
                Text("Count: \\(count)")
            }
        }
        """

        let module = RuntimeModule(source: source)
        let type = try module.type(named: "CounterView")
        let instance = try type.makeInstance()
        let renderer = try RuntimeViewRenderer(instance: instance)

        try assertViewMatch(renderer.renderedView, Text("Count: 0"))

        try renderer.instance.set("count", value: .int(5))

        try assertViewMatch(renderer.renderedView, Text("Count: 5"))
    }
}

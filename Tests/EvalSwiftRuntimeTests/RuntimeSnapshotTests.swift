import SwiftUI
import Testing
@testable import EvalSwiftRuntime

@MainActor
struct RuntimeSnapshotTests {
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
}

import SwiftUI
import Testing
@testable import EvalSwiftUI

@MainActor
struct SwiftUIEvaluatorBasicSnapshotTests {
    @Test func rendersTextLiteral() throws {
        #expectSnapshot(
            Text("Hello, SwiftUI!")
        )
    }

    @Test func rendersTextWithModifiers() throws {
        #expectSnapshot(
            Text("Hello, SwiftUI!")
                .font(.title)
                .padding()
        )
    }

    @Test func rendersTextUsingStringConcatenation() throws {
        #expectSnapshot(
            VStack {
                let name = "Taylor"
                Text("Hello, " + name + "!")
            }
        )
    }

    @Test func rendersVStackWithChildText() throws {
        #expectSnapshot(
            VStack {
                Text("Hello, SwiftUI!")
                    .font(.title)
                    .padding()
            }
        )
    }

    @Test func rendersImageWithModifiers() throws {
        #expectSnapshot(
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
        )
    }

    @Test func rendersSpacerInsideHStack() throws {
        #expectSnapshot(
            HStack(spacing: 0) {
                Text("Leading")
                    .foregroundStyle(.blue)
                Spacer(minLength: 8)
                Text("Trailing")
                    .foregroundStyle(.green)
            }
            .frame(width: 160)
        )
    }

    @Test func rendersNestedStacks() throws {
        #expectSnapshot(
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 4) {
                    Text("Left")
                    Text("Right")
                }
                Text("Bottom")
            }
        )
    }

    @Test func rendersAdvancedModifiers() throws {
        #expectSnapshot(
            Text("Styled")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(4)
                .foregroundStyle(.red)
                .frame(width: 120, height: 60, alignment: .leading)
                .frame(minWidth: 60, maxWidth: .infinity, alignment: .center)
        )
    }

    @Test func rendersZStack() throws {
        #expectSnapshot(
            ZStack(alignment: .topLeading) {
                Text("Background")
                    .padding(12)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Foreground")
                        .font(.headline)
                    Text("Detail")
                        .font(.caption)
                }
            }
        )
    }

    @Test func rendersBackgroundAndOverlayModifiers() throws {
        #expectSnapshot(
            Text("Decorated")
                .padding(12)
                .background(alignment: .bottomTrailing) {
                    VStack(spacing: 2) {
                        Text("BG Title")
                            .font(.caption)
                        Text("BG Detail")
                            .font(.caption2)
                    }
                    .padding(4)
                }
                .overlay {
                    VStack(spacing: 2) {
                        Text("Overlay Top")
                        Text("Overlay Bottom")
                    }
                }
        )
    }

    @Test func rendersRootViewAfterTopLevelStatements() throws {
        let source = """
        let greeting = "Hello"
        @State var count: Int = 0
        Text("\\(greeting), runtime!")
        """

        try assertSnapshotsMatch(source: source) {
            Text("Hello, runtime!")
        }
    }

    @Test func rendersStateInitialValue() throws {
        let source = """
        @State var count: Int = 5
        Text("Count: \\(count)")
        """

        try assertSnapshotsMatch(source: source) {
            Text("Count: 5")
        }
    }

    @Test func appliesCompoundAssignmentsBeforeRootView() throws {
        let source = """
        var count = 1
        count += 2
        Text("Count: \\(count)")
        """

        try assertSnapshotsMatch(source: source) {
            Text("Count: 3")
        }
    }

    @Test func rendersButtonUsingTitle() throws {
        #expectSnapshot(
            Button("Tap Me") {
                // Intentionally empty action
            }
        )
    }

    @Test func rendersButtonUsingLabelClosure() throws {
        #expectSnapshot(
            Button {
                // Intentionally empty action
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add Item")
                }
                .padding(6)
            }
        )
    }

    @Test func rendersMultipleRootViewsInsideVStack() throws {
        let source = """
        @State var count: Int = 0
        Text("Primary")
        Text("Secondary")
        """

        try assertSnapshotsMatch(source: source) {
            VStack(spacing: 0) {
                Text("Primary")
                Text("Secondary")
            }
        }
    }

    @Test func rendersInlineStructViews() throws {
        let source = """
        struct CountView: View {
            @State var count: Int = 0

            var body: some View {
                VStack(spacing: 4) {
                    Text("Count: \\(count)")
                    Button("Increase") {
                        count += 1
                    }
                }
            }
        }

        struct SomeOtherView: View {
            var body: some View {
                CountView()
            }
        }

        SomeOtherView()
        """

        try assertSnapshotsMatch(source: source) {
            ExpectedSomeOtherView()
        }
    }
}

private struct ExpectedCountView: View {
    @State var count: Int = 0

    var body: some View {
        VStack(spacing: 4) {
            Text("Count: \(count)")
            Button("Increase") {
                count += 1
            }
        }
    }
}

private struct ExpectedSomeOtherView: View {
    var body: some View {
        ExpectedCountView()
    }
}

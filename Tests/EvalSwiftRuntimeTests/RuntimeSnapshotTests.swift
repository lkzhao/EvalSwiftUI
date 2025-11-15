import SwiftUI
import Testing
@testable import EvalSwiftRuntime

@MainActor
struct RuntimeSnapshotTests {
    @Test func rendersTopLevelTextExpression() throws {
        #expectSnapshot(
            Text("Hello world!")
        )
    }
    @Test func rendersTopLevelVStackExpression() throws {
        #expectSnapshot(
            VStack {
                Text("Hello")
                Text("World!")
            }
        )
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

    @Test func rendersStandaloneButton() throws {
        #expectSnapshot(
            Button("Tap") {}
        )
    }

    @Test func rendersButtonWithLabelBuilder() throws {
        #expectSnapshot(
            Button {
            } label: {
                VStack {
                    Image(systemName: "plus")
                    Text("Tap")
                }
            }
        )
    }

    @Test func rendersVStackSpacingArgument() throws {
        #expectSnapshot(
            VStack(spacing: 16) {
                Text("Top")
                Text("Bottom")
            }
        )
    }

    @Test func rendersNestedVStacks() throws {
        #expectSnapshot(
            VStack(spacing: 8) {
                Text("Header")
                VStack(spacing: 4) {
                    Text("Row 1")
                    Text("Row 2")
                }
            }
        )
    }

    @Test func appliesPaddingModifier() throws {
        #expectSnapshot(
            Text("Padded")
                .padding(8)
        )
    }

    @Test func appliesBackgroundModifier() throws {
        #expectSnapshot(
            Text("Foreground")
                .padding(6)
                .background {
                    VStack(spacing: 0) {
                        Text("BG")
                        Text("BG")
                    }
                }
        )
    }

    @Test func rendersColorConstant() throws {
        #expectSnapshot(
            Color.blue
        )
    }

    @Test func rendersColorFromRGBInitializer() throws {
        #expectSnapshot(
            Color(red: 0.2, green: 0.4, blue: 0.6, opacity: 0.8)
        )
    }

    @Test func appliesBackgroundColor() throws {
        #expectSnapshot(
            Text("Tinted")
                .padding(4)
                .background(Color.red)
        )
    }

    @Test func appliesFontModifier() throws {
        #expectSnapshot(
            Text("Styled")
                .font(.title2)
        )
    }

    @Test func appliesForegroundStyleModifier() throws {
        #expectSnapshot(
            Text("Tinted")
                .foregroundStyle(.pink)
        )
    }

    @Test func rendersImageSystemSymbol() throws {
        #expectSnapshot(
            Image(systemName: "globe")
        )
    }

    @Test func rendersForEachOverRange() throws {
        #expectSnapshot(
            VStack {
                ForEach(0..<3) { index in
                    Text("Row \(index)")
                }
            }
        )
    }

    @Test func rendersForEachWithExplicitID() throws {
        #expectSnapshot(
            VStack {
                ForEach(["Alpha", "Beta", "Gamma"], id: \.self) { item in
                    Text(item)
                }
            }
        )
    }

    @Test func rendersForEachUsingShorthandParameters() throws {
        #expectSnapshot(
            VStack {
                ForEach(0..<2) {
                    Text("Value \($0)")
                }
            }
        )
    }

    @Test func rendersForEachUsingNestedShorthandParameters() throws {
        #expectSnapshot(
            VStack {
                ForEach(0..<2) {
                    let value = $0
                    VStack {
                        Text("Value \(value)")
                    }
                }
            }
        )
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

        let module = try RuntimeModule(source: source)
        let type = try module.type(named: "CounterView")
        guard let instance = try type.definitions.first!.build([], type).asInstance else {
            throw RuntimeError.invalidArgument("Expected CounterView instance.")
        }
        let renderer = try RuntimeViewRenderer(instance: instance)

        try assertViewMatch(renderer.renderedView, Text("Count: 0"))

        try renderer.instance.set("count", value: .int(5))

        try assertViewMatch(renderer.renderedView, Text("Count: 5"))
    }

//    @Test func appliesFontOpacityAndForegroundStyleModifiers() throws {
//        #expectSnapshot(
//            Text("Styled")
//                .font(.title2)
//                .foregroundStyle(.pink)
//                .opacity(0.65)
//        )
//    }
//
//    @Test func appliesFrameCornerRadiusAndShadowModifiers() throws {
//        #expectSnapshot(
//            Image(systemName: "star.fill")
//                .frame(width: 64, height: 64)
//                .cornerRadius(12)
//                .shadow(color: .black, radius: 4, x: 2, y: 3)
//        )
//    }
//
//    @Test func appliesBackgroundAndOverlayViews() throws {
//        #expectSnapshot(
//            Text("Badge")
//                .padding(8)
//                .background(.blue)
//                .overlay(alignment: .topTrailing) {
//                    Text("NEW")
//                        .font(.caption)
//                        .padding(4)
//                        .background(.white)
//                        .cornerRadius(8)
//                }
//        )
//    }
//
//    @Test func appliesImageScaleModifier() throws {
//        #expectSnapshot(
//            Image(systemName: "globe")
//                .imageScale(Image.Scale.large)
//                .foregroundStyle(.mint)
//        )
//    }
}

private struct CapsuleBackgroundModifierBuilder: RuntimeModifierBuilder {
    let name = "capsuleBackground"

    var definitions: [RuntimeModifierDefinition] {
        [
            RuntimeModifierDefinition(parameters: []) { view, _, _ in
                AnyView(
                    view
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                )
            }
        ]
    }
}

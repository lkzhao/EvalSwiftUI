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

    @Test func rendersTextFieldsWithModifiers() throws {
        let source = """
        enum Field {
            case email
            case password
        }

        @State var email: String = "user@example.com"
        @State var password: String = "secret"
        @State var showPassword: Bool = false
        @FocusState var focusedField: Field?

        VStack(spacing: 8) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focusedField, equals: .email)
                .onSubmit { focusedField = .password }
            Group {
                if showPassword {
                    TextField("Password", text: $password)
                } else {
                    SecureField("Password", text: $password)
                }
            }
            SecureField("Confirm password", text: $password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack(spacing: 8) {
                TextField("Email", text: .constant("user@example.com"))
                Group {
                    SecureField("Password", text: .constant("secret"))
                }
                SecureField("Confirm password", text: .constant("secret"))
            }
        }
    }

    @Test func rendersVStackSpacingArgument() throws {
        #expectSnapshot(
            VStack(spacing: 16) {
                Text("Top")
                Text("Bottom")
            }
        )
    }

    @Test func rendersVStackAlignment() throws {
        #expectSnapshot(
            VStack(alignment: .leading) {
                Text("Header")
                HStack(spacing: 4) {
                    Text("Left")
                    Text("Right")
                }
            }
        )
    }

    @Test func rendersHStackAlignmentAndSpacing() throws {
        #expectSnapshot(
            HStack(alignment: .bottom, spacing: 12) {
                VStack(spacing: 2) {
                    Text("Top")
                    Text("Bottom")
                }
                Text("Trailing")
                    .font(.headline)
            }
        )
    }

    @Test func rendersZStackAlignment() throws {
        #expectSnapshot(
            ZStack(alignment: .topLeading) {
                Color.blue
                    .frame(width: 80, height: 80)
                Text("Badge")
                    .padding(4)
                    .background(Color.white)
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

    @Test func appliesOverlayModifier() throws {
        #expectSnapshot(
            Color.blue
                .frame(width: 72, height: 40)
                .overlay(
                    Text("Hi")
                        .foregroundStyle(.white)
                )
        )
        #expectSnapshot(
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 80, height: 48)
                .foregroundStyle(.mint)
                .overlay(alignment: .topTrailing) {
                    Text("NEW")
                        .font(.caption)
                        .padding(4)
                        .background(Color.black.opacity(0.2))
                }
        )
        #expectSnapshot(
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 80, height: 48)
                .overlay(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
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
        #expectSnapshot(
            Text("Material")
                .padding(6)
                .foregroundStyle(.thinMaterial)
        )
    }

    @Test func appliesLinearGradientForegroundStyle() throws {
        let source = """
        Text("Linear")
            .padding(6)
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [.red, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        """

        try assertSnapshotsMatch(source: source) {
            Text("Linear")
                .padding(6)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.red, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @Test func appliesRadialGradientForegroundStyle() throws {
        let source = """
        Circle()
            .frame(width: 72, height: 72)
            .foregroundStyle(
                RadialGradient(
                    gradient: Gradient(stops: [
                        Gradient.Stop(color: .yellow, location: 0.0),
                        Gradient.Stop(color: .orange, location: 0.6),
                        Gradient.Stop(color: .red, location: 1.0)
                    ]),
                    center: .center,
                    startRadius: 6,
                    endRadius: 36
                )
            )
        """

        try assertSnapshotsMatch(source: source) {
            Circle()
                .frame(width: 72, height: 72)
                .foregroundStyle(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            Gradient.Stop(color: .yellow, location: 0.0),
                            Gradient.Stop(color: .orange, location: 0.6),
                            Gradient.Stop(color: .red, location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 6,
                        endRadius: 36
                    )
                )
        }
    }

    @Test func appliesAngularGradientForegroundStyle() throws {
        let source = """
        RoundedRectangle(cornerRadius: 20)
            .frame(width: 96, height: 48)
            .foregroundStyle(
                AngularGradient(
                    gradient: Gradient(colors: [.pink, .purple, .pink]),
                    center: .center,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 360)
                )
            )
        """

        try assertSnapshotsMatch(source: source) {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 96, height: 48)
                .foregroundStyle(
                    AngularGradient(
                        gradient: Gradient(colors: [.pink, .purple, .pink]),
                        center: .center,
                        startAngle: Angle(degrees: 0),
                        endAngle: Angle(degrees: 360)
                    )
                )
        }
    }

    @Test func appliesBorderModifier() throws {
        #expectSnapshot(
            Text("Bordered")
                .padding(6)
                .border(.purple, width: 2)
        )
    }

    @Test func appliesClipShapeModifier() throws {
        #expectSnapshot(
            Color.blue
                .frame(width: 60, height: 60)
                .clipShape(Circle())
        )
        #expectSnapshot(
            Rectangle()
                .frame(width: 72, height: 48)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12),
                    style: FillStyle(eoFill: true, antialiased: false)
                )
        )
    }

    @Test func appliesMaskModifier() throws {
        #expectSnapshot(
            Text("Masked")
                .padding(8)
                .background(Color.orange.opacity(0.7))
                .mask {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 90, height: 36)
                }
        )
        #expectSnapshot(
            Color.mint
                .frame(width: 64, height: 32)
                .mask(
                    Text("Hi")
                        .font(.title3)
                )
        )
    }

    @Test func appliesBlendModeModifier() throws {
        #expectSnapshot(
            ZStack {
                Color.black
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: 96, height: 48)
                    .foregroundStyle(.blue)
                Text("Glow")
                    .font(.headline)
                    .padding(4)
                    .foregroundStyle(.white)
                    .blendMode(.plusLighter)
            }
        )
    }

    @Test func rendersToggleWithTitleBinding() throws {
        let source = """
        @State var isOn: Bool = true

        Toggle("Enabled", isOn: $isOn)
        """

        try assertSnapshotsMatch(source: source) {
            Toggle("Enabled", isOn: .constant(true))
        }
    }

    @Test func rendersToggleWithCustomLabel() throws {
        let source = """
        @State var isOn: Bool = false

        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: "checkmark.circle")
                Text("Custom")
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            Toggle(isOn: .constant(false)) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Custom")
                }
            }
        }
    }

    @Test func rendersIfLetBinding() throws {
        let source = """
        @State var subtitle: String? = "Hello"

        if let message = subtitle {
            Text(message)
        }
        """

        try assertSnapshotsMatch(source: source) {
            Text("Hello")
        }
    }

    @Test func rendersIfLetElseBranch() throws {
        let source = """
        @State var subtitle: String? = nil

        if let message = subtitle {
            Text(message)
        } else {
            Text("Fallback")
        }
        """

        try assertSnapshotsMatch(source: source) {
            Text("Fallback")
        }
    }

    @Test func appliesColorOpacityModifier() throws {
        #expectSnapshot(
            Color.red.opacity(0.4)
        )
        #expectSnapshot(
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 48, height: 24)
                .foregroundStyle(Color.blue.opacity(0.3))
        )
    }

    @Test func rendersRoundedRectangleWithCornerRadius() throws {
        #expectSnapshot(
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 80, height: 40)
                .foregroundStyle(.mint)
        )
    }

    @Test func rendersRoundedRectangleWithContinuousStyle() throws {
        #expectSnapshot(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 60, height: 60)
                .foregroundStyle(Color.orange.opacity(0.7))
        )
    }

    @Test func rendersCircleShape() throws {
        #expectSnapshot(
            Circle()
                .frame(width: 48, height: 48)
                .foregroundStyle(.blue)
        )
    }

    @Test func rendersCapsuleShape() throws {
        #expectSnapshot(
            Capsule(style: .continuous)
                .frame(width: 80, height: 32)
                .foregroundStyle(Color.pink.opacity(0.8))
        )
    }

    @Test func rendersRectangleShape() throws {
        #expectSnapshot(
            Rectangle()
                .frame(width: 70, height: 30)
                .foregroundStyle(.gray)
        )
    }

    @Test func rendersLinearGradientWithColorArray() throws {
        let source = """
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [.indigo, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 48)
        """

        try assertSnapshotsMatch(source: source) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 48)
        }
    }

    @Test func rendersShapeFillAndStrokeModifiers() throws {
        let source = """
        VStack(spacing: 8) {
            Circle()
                .fill(.thinMaterial)
                .frame(width: 40, height: 40)
            RoundedRectangle(cornerRadius: 10)
                .stroke(.secondary, lineWidth: 4)
                .frame(width: 60, height: 30)
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.quaternary, lineWidth: 2)
                .frame(width: 60, height: 28)
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack(spacing: 8) {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 40, height: 40)
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.secondary, lineWidth: 4)
                    .frame(width: 60, height: 30)
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.quaternary, lineWidth: 2)
                    .frame(width: 60, height: 28)
            }
        }
    }

    @Test func appliesButtonStyleTintAndDisabled() throws {
        let source = """
        VStack(spacing: 8) {
            Button("Primary") {}
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            Button("Secondary") {}
                .buttonStyle(.bordered)
                .disabled(true)
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack(spacing: 8) {
                Button("Primary") {}
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                Button("Secondary") {}
                    .buttonStyle(.bordered)
                    .disabled(true)
            }
        }
    }

    @Test func appliesFontSystemWeightAndMultiline() throws {
        let source = """
        VStack(spacing: 4) {
            Text("System Weight")
                .font(.system(size: 22, weight: .semibold))
            Text("Bold Centered Text")
                .bold()
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack(spacing: 4) {
                Text("System Weight")
                    .font(.system(size: 22, weight: .semibold))
                Text("Bold Centered Text")
                    .bold()
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @Test func appliesAccessibilityAndPaddingEdges() throws {
        let source = """
        Text("Context")
            .padding(.top, 8)
            .background(Color(.systemGroupedBackground))
            .accessibilityLabel("Context Label")
            .accessibilityHidden(false)
        """

        try assertSnapshotsMatch(source: source) {
            Text("Context")
                .padding(.top, 8)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .accessibilityLabel(Text("Context Label"))
                .accessibilityHidden(false)
        }
    }
    @Test func rendersSpacerAndGroup() throws {
        let source = """
        VStack(spacing: 0) {
            Text("Top")
                .padding(4)
                .background(Color.blue.opacity(0.2))
            Spacer(minLength: 8)
            Group {
                Text("First")
                Text("Second")
            }
            Text("Bottom")
                .padding(4)
                .background(Color.green.opacity(0.2))
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack(spacing: 0) {
                Text("Top")
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                Spacer(minLength: 8)
                Group {
                    Text("First")
                    Text("Second")
                }
                Text("Bottom")
                    .padding(4)
                    .background(Color.green.opacity(0.2))
            }
        }
    }

    @Test func appliesImageScaleModifier() throws {
        #expectSnapshot(
            Image(systemName: "globe")
                .imageScale(.large)
        )
        #expectSnapshot(
            Image(systemName: "globe")
                .imageScale(Image.Scale.small)
        )
    }

    @Test func appliesOpacityModifier() throws {
        #expectSnapshot(
            Text("Ghost")
                .opacity(0.35)
        )
    }

    @Test func appliesShadowModifier() throws {
        #expectSnapshot(
            Text("Shadow")
                .padding(6)
                .background(Color.white)
                .shadow(radius: 4)
        )
        #expectSnapshot(
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 60, height: 36)
                .foregroundStyle(.mint)
                .shadow(color: .black.opacity(0.3), radius: 6, x: 2, y: 2)
        )
    }

    @Test func appliesFrameModifier() throws {
        #expectSnapshot(
            Text("Boxed")
                .frame(width: 80, height: 32, alignment: .center)
        )
        #expectSnapshot(
            Text("Boxed")
                .frame(height: 32, alignment: .center)
        )
        #expectSnapshot(
            Text("Boxed")
                .frame(height: 32, alignment: .center)
        )
        #expectSnapshot(
            Text("Boxed")
                .frame(alignment: .center)
        )
        #expectSnapshot(
            Text("Boxed")
                .frame(
                    minWidth: 40,
                    idealWidth: 80,
                    maxWidth: 120,
                    minHeight: 20,
                    idealHeight: 40,
                    maxHeight: 60,
                    alignment: .topLeading
                )
        )
    }

    @Test func rendersImageSystemSymbol() throws {
        #expectSnapshot(
            Image(systemName: "globe")
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

    @Test func rendersForEachWithModelKeyPathID() throws {
        let source = """
        struct TodoItem {
            var id: Int = 0
            var label: String = ""
        }

        let todos = [
            TodoItem(id: 1, label: "First"),
            TodoItem(id: 2, label: "Second"),
            TodoItem(id: 3, label: "Third")
        ]

        VStack(alignment: .leading, spacing: 4) {
            ForEach(todos, id: \\.id) { todo in
                Text(todo.label)
            }
        }
        """

        struct SnapshotTodo {
            var id: Int = 0
            var label: String = ""
        }

        let todos = [
            SnapshotTodo(id: 1, label: "First"),
            SnapshotTodo(id: 2, label: "Second"),
            SnapshotTodo(id: 3, label: "Third")
        ]

        try assertSnapshotsMatch(source: source) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(todos, id: \.id) { todo in
                    Text(todo.label)
                }
            }
        }
    }

    @Test func rendersForEachWithExplicitRootKeyPathID() throws {
        let source = """
        struct TodoItem {
            var id: Int = 0
            var label: String = ""
        }

        let todos = [
            TodoItem(id: 10, label: "One"),
            TodoItem(id: 11, label: "Two")
        ]

        VStack(alignment: .leading, spacing: 4) {
            ForEach(todos, id: \\TodoItem.id) { todo in
                Text(todo.label)
            }
        }
        """

        struct SnapshotTodo {
            var id: Int = 0
            var label: String = ""
        }

        let todos = [
            SnapshotTodo(id: 10, label: "One"),
            SnapshotTodo(id: 11, label: "Two")
        ]

        try assertSnapshotsMatch(source: source) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(todos, id: \.id) { todo in
                    Text(todo.label)
                }
            }
        }
    }

    @Test func rendersForEachWithSubscriptKeyPathID() throws {
        let source = """
        struct TodoItem {
            var id: Int = 0
            var label: String = ""
        }

        struct Group {
            var items: [TodoItem] = []
        }

        let groups = [
            Group(items: [TodoItem(id: 101, label: "Alpha")]),
            Group(items: [TodoItem(id: 102, label: "Beta")])
        ]

        VStack(alignment: .leading, spacing: 4) {
            ForEach(groups, id: \\.items[0].id) { group in
                Text(group.items[0].label)
            }
        }
        """

        struct SnapshotTodo {
            var id: Int = 0
            var label: String = ""
        }

        struct SnapshotGroup {
            var items: [SnapshotTodo] = []
        }

        let groups = [
            SnapshotGroup(items: [SnapshotTodo(id: 101, label: "Alpha")]),
            SnapshotGroup(items: [SnapshotTodo(id: 102, label: "Beta")])
        ]

        try assertSnapshotsMatch(source: source) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(groups, id: \.items[0].id) { group in
                    Text(group.items[0].label)
                }
            }
        }
    }

    @Test func rendersForEachWithUUIDIdentifiers() throws {
        let source = """
        let ids = [
            UUID(),
            UUID()
        ]

        VStack(alignment: .leading, spacing: 4) {
            ForEach(ids, id: \\.self) { _ in
                Text("UUID item")
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach([UUID(), UUID()], id: \.self) { _ in
                    Text("UUID item")
                }
            }
        }
    }

    @Test func rendersForEachWithIdentifiableStructs() throws {
        let source = """
        struct TodoItem: Identifiable {
            var id: UUID = UUID()
            var label: String = ""
        }

        let todos = [
            TodoItem(label: "Identifiable One"),
            TodoItem(label: "Identifiable Two")
        ]

        VStack(alignment: .leading, spacing: 4) {
            ForEach(todos) { todo in
                Text(todo.label)
            }
        }
        """

        struct SnapshotTodo: Identifiable {
            var id: UUID = UUID()
            var label: String = ""
        }

        let todos = [
            SnapshotTodo(label: "Identifiable One"),
            SnapshotTodo(label: "Identifiable Two")
        ]

        try assertSnapshotsMatch(source: source) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(todos) { todo in
                    Text(todo.label)
                }
            }
        }
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

    @Test func rendersForEachUsingParameters() throws {
        #expectSnapshot(
            VStack {
                ForEach(0..<2) { item in
                    VStack {
                        Text("Value \(item)")
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
}

private struct CapsuleBackgroundModifierBuilder: RuntimeModifierBuilder {
    let name = "capsuleBackground"

    var definitions: [RuntimeModifierDefinition] {
        [
            RuntimeViewModifierDefinition(parameters: []) { view, _, _ in
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

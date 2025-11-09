import SwiftParser
import SwiftUI
import Testing
@testable import EvalSwiftUI

@MainActor
struct SwiftUIEvaluatorStateTests {
    @Test func stateMutationTriggersDifferentRender() throws {
        let source = """
        @State var count: Int = 0
        VStack(spacing: 8) {
            Text("Count: \\(count)")
        }
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        store.reset()
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        let initialView = try coordinator.render()
        let initialSnapshot = try ViewSnapshotRenderer.snapshot(from: initialView)

        guard let reference = store.reference(for: "count") else {
            throw TestFailure.expected("Missing state slot")
        }
        reference.write(.number(1))

        let updatedView = try coordinator.render()
        let updatedSnapshot = try ViewSnapshotRenderer.snapshot(from: updatedView)

        #expect(initialSnapshot != updatedSnapshot)
    }

    @Test func counterButtonUpdatesState() throws {
        let source = """
        @State var count: Int = 0
        VStack {
            Text("Count: \\(count)")
            Button("Increase") {
                count += 1
            }
        }
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        let initialView = try coordinator.render()
        let initialSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(initialView))

        guard let countState = store.reference(for: "count") else {
            throw TestFailure.expected("Missing count state slot")
        }

        countState.write(.number(1))
        let updatedView = try coordinator.render()
        let updatedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(updatedView))

        #expect(initialSnapshot != updatedSnapshot)
    }

    @Test func multipleRootViewsMaintainOrderingAfterStateChange() throws {
        let source = """
        @State var count: Int = 0
        Text("Count: \\(count)")
        Text("Static")
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        _ = try coordinator.render()

        guard let countSlot = store.reference(for: "count") else {
            throw TestFailure.expected("Missing count state slot")
        }

        countSlot.write(.number(1))
        let updatedView = try coordinator.render()
        let updatedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(updatedView))

        let expectedView = VStack(spacing: 0) {
            Text("Count: 1")
            Text("Static")
        }
        let expectedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(expectedView))

        #expect(updatedSnapshot == expectedSnapshot)
    }

    @Test func rendersForEachFromStateArray() throws {
        let source = """
        @State var countIds = [0, 1, 2]
        VStack {
            ForEach(countIds, id: \\.self) {
                Text("Count \\($0)")
            }
        }
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        let renderedView = try coordinator.render()
        let renderedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(renderedView))

        let expected = VStack {
            ForEach([0, 1, 2], id: \.self) { value in
                Text("Count \(value)")
            }
        }
        let expectedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(expected))

        #expect(renderedSnapshot == expectedSnapshot)
    }

    @Test func rendersStatefulRowsInsideForEach() throws {
        let source = """
        struct CountView: View {
            @State var count = 0

            var body: some View {
                VStack {
                    Text("State \\(count)")
                }
            }
        }

        @State var countIds = [0, 1, 2]
        ForEach(countIds, id: \\.self) {
            HStack {
                Text("ID \\($0)")
                CountView()
            }
        }
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        let renderedView = try coordinator.render()
        let renderedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(renderedView))

        let expected = ForEach([0, 1, 2], id: \.self) { value in
            HStack {
                Text("ID \(value)")
                ExpectedInlineCountView()
            }
        }
        let expectedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(expected))

        #expect(renderedSnapshot == expectedSnapshot)
    }

    @Test func inlineStructInstancesMaintainIndependentState() throws {
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

        struct Container: View {
            var body: some View {
                VStack(spacing: 0) {
                    CountView()
                    CountView()
                }
            }
        }

        Container()
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        _ = try coordinator.render()

        guard let first = store.reference(for: "CountView#0.count"),
              let second = store.reference(for: "CountView#1.count") else {
            throw TestFailure.expected("Missing inline state references")
        }

        first.write(.number(1))
        #expect(second.read().equals(.number(0)))

        second.write(.number(2))
        #expect(first.read().equals(.number(1)))

        let updatedView = try coordinator.render()
        let updatedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(updatedView))

        let expected = ExpectedInlineStructContainer(counts: [1, 2])
        let expectedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(expected))

        #expect(updatedSnapshot == expectedSnapshot)
    }

    @Test func preservesChildStateWhenReorderingForEachData() throws {
        let source = """
        struct CountView: View {
            @State var count: Int = 0

            var body: some View {
                Text("Count: \\(count)")
            }
        }

        struct Host: View {
            @State var ids = [0, 1, 2]

            var body: some View {
                VStack {
                    ForEach(ids, id: \\.self) { _ in
                        CountView()
                    }
                }
            }
        }

        Host()
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        _ = try coordinator.render()

        let countReferences = try rowStateReferences(in: store)
        for (row, reference) in countReferences {
            reference.write(.number(Double(row + 10)))
        }

        guard let idsIdentifier = store.identifiers().first(where: { $0.hasSuffix(".ids") }),
              let idsReference = store.reference(for: idsIdentifier) else {
            throw TestFailure.expected("Missing ids state reference")
        }
        idsReference.write(.array([.number(2), .number(1), .number(0)]))

        _ = try coordinator.render()

        for (row, reference) in countReferences {
            #expect(reference.read().equals(.number(Double(row + 10))))
        }
    }

    @Test func toggleReflectsStateChanges() throws {
        let source = """
        @State var isOn = false
        Toggle("Wi-Fi", isOn: $isOn)
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        let initialView = try coordinator.render()
        let initialSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(initialView))

        let expectedOff = Toggle(isOn: .constant(false)) {
            Text("Wi-Fi")
        }
        let expectedOffSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(expectedOff))

        #expect(initialSnapshot == expectedOffSnapshot)

        guard let isOnReference = store.reference(for: "isOn") else {
            throw TestFailure.expected("Missing binding for isOn")
        }

        isOnReference.write(.bool(true))

        let updatedView = try coordinator.render()
        let updatedSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(updatedView))

        let expectedOn = Toggle(isOn: .constant(true)) {
            Text("Wi-Fi")
        }
        let expectedOnSnapshot = try ViewSnapshotRenderer.snapshot(from: AnyView(expectedOn))

        #expect(updatedSnapshot == expectedOnSnapshot)
    }

    @Test func shuffleMutatesStateArray() throws {
        let source = """
        @State var numbers = [0, 1, 2, 3]
        numbers.shuffle()
        VStack {
            ForEach(numbers, id: \\.self) { value in
                Text("Value \\(value)")
            }
        }
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        _ = try coordinator.render()

        guard let numbersReference = store.reference(for: "numbers") else {
            throw TestFailure.expected("Missing numbers state slot")
        }

        let values = try intArray(from: numbersReference.read())
        #expect(values.sorted() == [0, 1, 2, 3])
        #expect(values != [0, 1, 2, 3])
    }

    @Test func shuffledProducesNewArrayWithoutMutatingOriginal() throws {
        let source = """
        @State var numbers = [0, 1, 2, 3]
        @State var randomized: [Int] = []
        randomized = numbers.shuffled()
        VStack {
            ForEach(randomized, id: \\.self) { value in
                Text("Randomized \\(value)")
            }
        }
        """

        let store = RuntimeStateStore()
        let evaluator = SwiftUIEvaluator(stateStore: store)
        let syntax = Parser.parse(source: source)
        let coordinator = RuntimeRenderCoordinator(evaluator: evaluator, syntax: syntax)

        _ = try coordinator.render()

        guard let numbersReference = store.reference(for: "numbers"),
              let randomizedReference = store.reference(for: "randomized") else {
            throw TestFailure.expected("Missing state slots for shuffled verification")
        }

        let originalValues = try intArray(from: numbersReference.read())
        let shuffledValues = try intArray(from: randomizedReference.read())

        #expect(originalValues == [0, 1, 2, 3])
        #expect(shuffledValues.sorted() == [0, 1, 2, 3])
        #expect(shuffledValues != originalValues)
    }
}

private struct ExpectedInlineStructContainer: View {
    let counts: [Int]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(counts.enumerated()), id: \.0) { _, value in
                VStack(spacing: 4) {
                    Text("Count: \(value)")
                    Button("Increase") {}
                }
            }
        }
    }
}

private struct ExpectedInlineCountView: View {
    var body: some View {
        VStack {
            Text("State 0")
        }
    }
}

private func rowStateReferences(in store: RuntimeStateStore) throws -> [Int: StateReference] {
    var references: [Int: StateReference] = [:]
    for identifier in store.identifiers() where identifier.contains("CountView#") {
        guard let rowValue = rowValueFromIdentifier(identifier),
              let reference = store.reference(for: identifier) else {
            continue
        }
        references[rowValue] = reference
    }
    guard references.count >= 1 else {
        throw TestFailure.expected("Missing CountView state references")
    }
    return references
}

private func rowValueFromIdentifier(_ identifier: String) -> Int? {
    guard let rowRange = identifier.range(of: ".row-") else {
        return nil
    }
    let remainder = identifier[rowRange.upperBound...]
    guard let endRange = remainder.range(of: ".CountView") else {
        return nil
    }
    let valueSubstring = remainder[..<endRange.lowerBound]
    return Int(valueSubstring)
}

private func intArray(from value: SwiftValue) throws -> [Int] {
    switch value.payload {
    case .array(let elements):
        return try elements.map { element in
            try intValue(from: element)
        }
    case .optional(let wrapped):
        guard let wrapped else {
            throw TestFailure.expected("Expected array value, received nil.")
        }
        return try intArray(from: wrapped)
    default:
        throw TestFailure.expected("Expected array value from state store.")
    }
}

private func intValue(from value: SwiftValue) throws -> Int {
    switch value.payload {
    case .number(let number):
        guard number.truncatingRemainder(dividingBy: 1) == 0 else {
            throw TestFailure.expected("Expected integer element in array.")
        }
        return Int(number)
    case .optional(let wrapped):
        guard let wrapped else {
            throw TestFailure.expected("Expected integer element, received nil.")
        }
        return try intValue(from: wrapped)
    default:
        throw TestFailure.expected("Expected numeric element in array.")
    }
}

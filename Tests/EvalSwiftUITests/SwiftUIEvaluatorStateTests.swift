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
}

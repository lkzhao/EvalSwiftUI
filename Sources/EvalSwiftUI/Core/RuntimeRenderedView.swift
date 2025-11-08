import SwiftSyntax
import SwiftUI

struct RuntimeRenderedView: View {
    @State private var version: UInt = 0
    @State private var renderedView: AnyView

    private let coordinator: RuntimeRenderCoordinator
    private let stateStore: RuntimeStateStore

    init(initialView: AnyView,
         coordinator: RuntimeRenderCoordinator,
         stateStore: RuntimeStateStore) {
        _renderedView = State(initialValue: initialView)
        self.coordinator = coordinator
        self.stateStore = stateStore
    }

    var body: some View {
        renderedView
            .onAppear(perform: configureChangeHandler)
            .onChange(of: version) { _ in
                updateRenderedView()
            }
            .onDisappear {
                stateStore.onChange = nil
            }
    }

    private func configureChangeHandler() {
        stateStore.onChange = {
            version &+= 1
        }
    }

    private func updateRenderedView() {
        do {
            renderedView = try coordinator.render()
        } catch {
            renderedView = AnyView(
                VStack(spacing: 8) {
                    Text("Runtime Error")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                }
            )
        }
    }
}

final class RuntimeRenderCoordinator {
    private let evaluator: SwiftUIEvaluator
    private let syntax: SourceFileSyntax

    init(evaluator: SwiftUIEvaluator, syntax: SourceFileSyntax) {
        self.evaluator = evaluator
        self.syntax = syntax
    }

    func render() throws -> AnyView {
        try evaluator.renderSyntax(from: syntax)
    }
}

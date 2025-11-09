import SwiftSyntax
import SwiftUI

struct RuntimeRenderedView: View {
    @State private var version: UInt = 0
    @State private var renderedView: AnyView

    private let evaluator: SwiftUIEvaluator
    private let syntax: SourceFileSyntax
    private let stateStore: RuntimeStateStore

    init(initialView: AnyView,
         evaluator: SwiftUIEvaluator,
         syntax: SourceFileSyntax,
         stateStore: RuntimeStateStore) {
        _renderedView = State(initialValue: initialView)
        self.evaluator = evaluator
        self.syntax = syntax
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
            renderedView = try evaluator.renderSyntax(from: syntax)
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

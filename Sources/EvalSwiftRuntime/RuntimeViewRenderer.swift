import Combine
import Foundation
import SwiftUI

@MainActor
final class RuntimeViewRenderer: ObservableObject {
    @Published private(set) var renderedView: AnyView
    private(set) var runtimeValue: RuntimeValue

    let module: RuntimeModule
    let definition: CompiledViewDefinition
    let scope: RuntimeScope
    var isRendering = false

    init(
        definition: CompiledViewDefinition,
        module: RuntimeModule,
        parentScope: RuntimeScope,
        parameters: [RuntimeParameter]
    ) throws {
        self.definition = definition
        self.module = module
        self.scope = try definition.makeInstanceScope(parentScope: parentScope, parameters: parameters)
        self.runtimeValue = .void
        self.renderedView = AnyView(EmptyView())

        try rerender()
        scope.mutationHandler = { [weak self] _, _ in
            guard let self else { return }
            if Thread.isMainThread {
                try? self.rerender()
            } else {
                Task { @MainActor in
                    try? self.rerender()
                }
            }
        }
    }

    private func rerender() throws {
        guard !isRendering else { return }
        isRendering = true
        defer { isRendering = false }

        let nextValue = try definition.renderBody(in: scope)
        runtimeValue = nextValue
        renderedView = try module.realize(runtimeValue: nextValue, scope: scope)
    }
}

struct RuntimeViewHost: View {
    @StateObject private var renderer: RuntimeViewRenderer

    init(renderer: RuntimeViewRenderer) {
        _renderer = StateObject(wrappedValue: renderer)
    }

    var body: some View {
        renderer.renderedView
    }
}

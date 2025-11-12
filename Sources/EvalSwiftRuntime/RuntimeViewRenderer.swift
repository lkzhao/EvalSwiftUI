import Combine
import Foundation
import SwiftUI

@MainActor
final class RuntimeViewRenderer: ObservableObject {
    @Published private(set) var renderedView: AnyView
    private(set) var runtimeValue: RuntimeValue

    let module: RuntimeModule
    let definition: CompiledViewDefinition
    let instance: RuntimeInstance
    var isRendering = false

    init(
        definition: CompiledViewDefinition,
        module: RuntimeModule,
        arguments: [RuntimeArgument],
        scope: RuntimeScope,
    ) throws {
        self.definition = definition
        self.module = module
        self.instance = try definition.makeInstance(arguments: arguments, scope: scope)
        self.runtimeValue = .void
        self.renderedView = AnyView(EmptyView())

        try rerender()
        instance.mutationHandler = { [weak self] _, _ in
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

        guard let nextValue = try instance.callMethod("body") else {
            throw RuntimeError.invalidViewResult("View body did not return a value")
        }
        runtimeValue = nextValue
        renderedView = try module.realize(runtimeValue: nextValue, scope: instance)
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

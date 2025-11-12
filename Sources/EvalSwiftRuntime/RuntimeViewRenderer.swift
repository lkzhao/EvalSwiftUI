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
        parentInstance: RuntimeInstance,
        parameters: [RuntimeParameter]
    ) throws {
        self.definition = definition
        self.module = module
        self.instance = try definition.makeInstance(parentInstance: parentInstance, parameters: parameters)
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

        let nextValue = try instance.callMethod("body")
        runtimeValue = nextValue
        renderedView = try module.realize(runtimeValue: nextValue, instance: instance)
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

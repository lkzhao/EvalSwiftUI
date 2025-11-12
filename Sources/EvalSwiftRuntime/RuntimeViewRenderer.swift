import Combine
import Foundation
import SwiftUI
import EvalSwiftIR

@MainActor
final class RuntimeViewRenderer: ObservableObject {
    @Published private(set) var renderedView: AnyView

    let definition: ViewDefinition
    let instance: RuntimeInstance
    var isRendering = false

    init(
        definition: ViewDefinition,
        arguments: [RuntimeArgument] = [],
        scope: RuntimeScope,
    ) throws {
        self.definition = definition
        self.instance = try definition.makeInstance(arguments: arguments, scope: scope)
        self.renderedView = AnyView(EmptyView())

        try rerender()
        instance.mutationHandler = { [weak self] in
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

        let bodyFunction = try instance.getFunction("body")
        let views = try bodyFunction.renderRuntimeViews(scope: instance).map {
            try $0.makeSwiftUIView(scope: instance)
        }
        renderedView = AnyView(ForEach(Array(views.enumerated()), id: \.0) { _, view in
            view
        })
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

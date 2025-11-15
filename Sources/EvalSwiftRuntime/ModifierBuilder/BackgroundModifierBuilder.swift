import SwiftUI

public struct BackgroundModifierBuilder: RuntimeModifierBuilder {
    public let name = "background"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "content", type: "() -> Content")
                ],
                apply: { view, arguments, _ in
                    let backgroundView = try Self.makeBackgroundView(
                        from: arguments.value(named: "content")?.asFunction
                    )
                    return AnyView(view.background(backgroundView))
                }
            ),
            RuntimeModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "view", type: "Any")
                ],
                apply: { view, arguments, _ in
                    guard let background = arguments.value(named: "view")?.asSwiftUIView else {
                        throw RuntimeError.invalidArgument("background(_:) expects a SwiftUI view.")
                    }
                    return AnyView(view.background(background))
                }
            )
        ]
    }

    private static func makeBackgroundView(from function: RuntimeFunction?) throws -> AnyView {
        guard let function else {
            throw RuntimeError.invalidArgument("background requires a view-building closure.")
        }
        let renderedValues = try function.renderRuntimeViews()
        if let view = renderedValues.compactMap({ $0.asSwiftUIView }).first {
            return view
        }
        throw RuntimeError.invalidArgument("background closure must return a SwiftUI view.")
    }
}

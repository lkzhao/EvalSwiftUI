import SwiftUI

public struct BackgroundModifierBuilder: RuntimeModifierBuilder {
    public let name = "background"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "content", type: "Any")
                ],
                apply: { view, arguments, _ in
                    if let function = arguments.value(named: "content")?.asFunction {
                        let backgroundView = try Self.makeBackgroundView(from: function)
                        return AnyView(view.background(backgroundView))
                    }
                    guard let background = arguments.value(named: "content")?.asSwiftUIView else {
                        throw RuntimeError.invalidArgument("background expects a SwiftUI view.")
                    }
                    return AnyView(view.background(background))
                }
            )
        ]
    }

    private static func makeBackgroundView(from function: RuntimeFunction) throws -> AnyView {
        let renderedValues = try function.renderRuntimeViews()
        if let view = renderedValues.compactMap({ $0.asSwiftUIView }).first {
            return view
        }
        throw RuntimeError.invalidArgument("background closure must return a SwiftUI view.")
    }
}

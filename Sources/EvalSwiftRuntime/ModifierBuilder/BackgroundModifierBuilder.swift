import SwiftUI

public struct BackgroundModifierBuilder: RuntimeMethodBuilder {
    public let name = "background"
    public let definitions: [RuntimeMethodDefinition]

    public init() {
        definitions = [
            RuntimeViewMethodDefinition(
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

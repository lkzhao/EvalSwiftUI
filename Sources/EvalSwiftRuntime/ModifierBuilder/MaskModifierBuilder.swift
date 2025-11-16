import SwiftUI

public struct MaskModifierBuilder: RuntimeMethodBuilder {
    public let name = "mask"
    public let definitions: [RuntimeMethodDefinition]

    public init() {
        definitions = [
            RuntimeViewMethodDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "content", type: "Any")
                ],
                apply: { view, arguments, _ in
                    if let function = arguments.value(named: "content")?.asFunction {
                        let maskView = try Self.makeMaskView(from: function)
                        return AnyView(view.mask(maskView))
                    }
                    guard let maskView = arguments.value(named: "content")?.asSwiftUIView else {
                        throw RuntimeError.invalidArgument("mask expects a SwiftUI view.")
                    }
                    return AnyView(view.mask(maskView))
                }
            ),
            RuntimeViewMethodDefinition(
                parameters: [
                    RuntimeParameter(
                        name: "alignment",
                        type: "Alignment",
                        defaultValue: .swiftUI(.alignment(.center))
                    ),
                    RuntimeParameter(name: "content", type: "() -> Content")
                ],
                apply: { view, arguments, _ in
                    let alignment = arguments.value(named: "alignment")?.asAlignment ?? .center
                    guard let function = arguments.value(named: "content")?.asFunction else {
                        throw RuntimeError.invalidArgument("mask requires a content closure.")
                    }
                    let maskView = try Self.makeMaskView(from: function)
                    return AnyView(view.mask(alignment: alignment) {
                        maskView
                    })
                }
            )
        ]
    }

    private static func makeMaskView(from function: RuntimeFunction) throws -> AnyView {
        let renderedValues = try function.renderRuntimeViews()
        if let view = renderedValues.compactMap({ $0.asSwiftUIView }).first {
            return view
        }
        throw RuntimeError.invalidArgument("mask closure must return a SwiftUI view.")
    }
}

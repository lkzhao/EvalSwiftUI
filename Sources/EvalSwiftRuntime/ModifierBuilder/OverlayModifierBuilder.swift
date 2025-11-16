import SwiftUI

public struct OverlayModifierBuilder: RuntimeModifierBuilder {
    public let name = "overlay"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "content", type: "Any"),
                    RuntimeParameter(
                        name: "alignment",
                        type: "Alignment",
                        defaultValue: .swiftUI(.alignment(.center))
                    )
                ],
                apply: { view, arguments, _ in
                    let alignment = arguments.value(named: "alignment")?.asAlignment ?? .center
                    if let function = arguments.value(named: "content")?.asFunction {
                        let overlayView = try Self.makeOverlayView(from: function)
                        return AnyView(view.overlay(alignment: alignment) {
                            overlayView
                        })
                    }
                    guard let overlayView = arguments.value(named: "content")?.asSwiftUIView else {
                        throw RuntimeError.invalidArgument("overlay expects a SwiftUI view.")
                    }
                    return AnyView(view.overlay(overlayView, alignment: alignment))
                }
            ),
            RuntimeViewModifierDefinition(
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
                        throw RuntimeError.invalidArgument("overlay requires a content closure.")
                    }
                    let overlayView = try Self.makeOverlayView(from: function)
                    return AnyView(view.overlay(alignment: alignment) {
                        overlayView
                    })
                }
            ),
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "content", type: "Color"),
                    RuntimeParameter(
                        name: "alignment",
                        type: "Alignment",
                        defaultValue: .swiftUI(.alignment(.center))
                    )
                ],
                apply: { view, arguments, _ in
                    let alignment = arguments.value(named: "alignment")?.asAlignment ?? .center
                    guard let color = arguments.value(named: "content")?.asColor else {
                        throw RuntimeError.invalidArgument("overlay expects a Color value.")
                    }
                    return AnyView(view.overlay(color, alignment: alignment))
                }
            ),
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "style", type: "ShapeStyle"),
                    RuntimeParameter(label: "in", name: "shape", type: "Shape")
                ],
                apply: { view, arguments, _ in
                    guard let style = arguments.value(named: "style")?.asShapeStyle else {
                        throw RuntimeError.invalidArgument("overlay expects a ShapeStyle value.")
                    }
                    guard let shape = arguments.value(named: "shape")?.asShape else {
                        throw RuntimeError.invalidArgument("overlay expects a Shape value for the 'in' parameter.")
                    }
                    return AnyView(view.overlay(style, in: shape))
                }
            )
        ]
    }

    private static func makeOverlayView(from function: RuntimeFunction) throws -> AnyView {
        let renderedValues = try function.renderRuntimeViews()
        if let view = renderedValues.compactMap({ $0.asSwiftUIView }).first {
            return view
        }
        throw RuntimeError.invalidArgument("overlay closure must return a SwiftUI view.")
    }
}

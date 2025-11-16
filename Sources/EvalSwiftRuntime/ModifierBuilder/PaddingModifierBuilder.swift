import SwiftUI

public struct PaddingModifierBuilder: RuntimeModifierBuilder {
    public let name = "padding"
    public let definitions: [RuntimeModifierDefinition]

    public init() {
        definitions = [
            RuntimeViewModifierDefinition(
                parameters: [],
                apply: { view, _, _ in
                    AnyView(view.padding())
                }
            ),
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "value", type: "Double")
                ],
                apply: { view, arguments, _ in
                    guard let amount = arguments.value(named: "value")?.asDouble else {
                        throw RuntimeError.invalidArgument("padding(_:) expects a numeric argument.")
                    }
                    return AnyView(view.padding(CGFloat(amount)))
                }
            ),
            RuntimeViewModifierDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "edges", type: "Edge.Set"),
                    RuntimeParameter(label: "_", name: "length", type: "Double", defaultValue: .void)
                ],
                apply: { view, arguments, _ in
                    guard let edges = arguments.value(named: "edges")?.asEdgeSet else {
                        throw RuntimeError.invalidArgument("padding(_:_: ) expects an Edge.Set for the first argument.")
                    }
                    let length = arguments.value(named: "length")?.asCGFloat
                    if let length {
                        return AnyView(view.padding(edges, length))
                    }
                    return AnyView(view.padding(edges))
                }
            )
        ]
    }
}

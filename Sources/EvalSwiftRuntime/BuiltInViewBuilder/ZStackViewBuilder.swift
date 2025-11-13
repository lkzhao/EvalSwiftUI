import SwiftUI

public struct ZStackViewBuilder: RuntimeViewBuilder {
    public let typeName = "ZStack"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var alignment: Alignment = .center
        var childViews: [AnyView] = []

        for argument in arguments {
            if argument.label == "alignment" {
                guard let newAlignment = argument.value.asAlignment else {
                    throw RuntimeError.invalidViewArgument("alignment must be an Alignment value.")
                }
                alignment = newAlignment
                continue
            }

            try appendChildViews(from: argument.value, into: &childViews)
        }

        return AnyView(ZStack(alignment: alignment) {
            ForEach(Array(childViews.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }

    @MainActor
    private func appendChildViews(from value: RuntimeValue, into childViews: inout [AnyView]) throws {
        switch value {
        case .array(let values):
            for value in values {
                try appendChildViews(from: value, into: &childViews)
            }
        case .instance(let instance):
            childViews.append(try instance.makeSwiftUIView())
        case .function(let function):
            let views = try function.renderRuntimeViews()
            for runtimeView in views {
                childViews.append(try runtimeView.makeSwiftUIView())
            }
        default:
            break
        }
    }
}

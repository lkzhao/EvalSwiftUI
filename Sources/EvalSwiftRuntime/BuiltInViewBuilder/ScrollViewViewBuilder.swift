import SwiftUI

public struct ScrollViewViewBuilder: RuntimeViewBuilder {
    public let typeName = "ScrollView"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var axis: Axis.Set = .vertical
        var showsIndicators = true
        var axisConfigured = false
        var indicatorsConfigured = false
        var childViews: [AnyView] = []

        for argument in arguments {
            if let label = argument.label {
                switch label {
                case "axis", "axes":
                    axis = try resolveAxis(from: argument.value)
                    axisConfigured = true
                    continue
                case "showsIndicators":
                    showsIndicators = try resolveIndicators(from: argument.value)
                    indicatorsConfigured = true
                    continue
                case "content":
                    try appendChildViews(from: argument.value, into: &childViews)
                    continue
                default:
                    try appendChildViews(from: argument.value, into: &childViews)
                    continue
                }
            }

            if !axisConfigured, let axisSet = argument.value.asAxisSet {
                axis = axisSet
                axisConfigured = true
                continue
            }

            if !indicatorsConfigured, let boolValue = argument.value.asBool {
                showsIndicators = boolValue
                indicatorsConfigured = true
                continue
            }

            try appendChildViews(from: argument.value, into: &childViews)
        }

        return AnyView(ScrollView(axis, showsIndicators: showsIndicators) {
            ForEach(Array(childViews.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }

    private func resolveAxis(from value: RuntimeValue) throws -> Axis.Set {
        guard let axisSet = value.asAxisSet else {
            throw RuntimeError.invalidViewArgument("ScrollView axis arguments must be Axis.Set values.")
        }
        return axisSet
    }

    private func resolveIndicators(from value: RuntimeValue) throws -> Bool {
        guard let boolValue = value.asBool else {
            throw RuntimeError.invalidViewArgument("showsIndicators must be a Bool value.")
        }
        return boolValue
    }

    @MainActor
    private func appendChildViews(from value: RuntimeValue, into childViews: inout [AnyView]) throws {
        switch value {
        case .array(let values):
            try values.forEach { try appendChildViews(from: $0, into: &childViews) }
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

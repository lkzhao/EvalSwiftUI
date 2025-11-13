import SwiftUI

public struct BackgroundModifierBuilder: RuntimeModifierBuilder {
    public let modifierName = "background"

    public init() {}

    @MainActor
    public func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var alignment: Alignment = .center
        var contentArgument: RuntimeArgument?
        var contentFunction: RuntimeArgument?

        for argument in arguments {
            if argument.label == "alignment" {
                guard let alignmentValue = argument.value.asAlignment else {
                    throw RuntimeError.invalidViewArgument("alignment expects an Alignment value.")
                }
                alignment = alignmentValue
                continue
            }

            if argument.label == "content", case .function = argument.value {
                contentFunction = argument
                continue
            }

            if case .function = argument.value {
                contentFunction = argument
                continue
            }

            if contentArgument == nil {
                contentArgument = argument
            }
        }

        if let function = contentFunction {
            guard let overlay = function.value.asSwiftUIView else {
                throw RuntimeError.invalidViewArgument("background modifier expects a view or closure providing one.")
            }
            return AnyView(view.background(alignment: alignment) { overlay })
        }

        if let argument = contentArgument {
            guard let overlay = argument.value.asSwiftUIView else {
                throw RuntimeError.invalidViewArgument("background modifier expects a view or closure providing one.")
            }
            return AnyView(view.background(alignment: alignment) { overlay })
        }

        throw RuntimeError.invalidViewArgument("background modifier expects a view or closure providing one.")
    }
}

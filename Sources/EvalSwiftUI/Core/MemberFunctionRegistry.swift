import SwiftUI

public protocol MemberFunctionHandler {
    var name: String { get }
    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue
}

final class MemberFunctionRegistry: ModifierDispatching {
    private var handlers: [String: any MemberFunctionHandler]

    init(additionalHandlers: [any MemberFunctionHandler] = []) {
        handlers = [:]
        for handler in Self.defaultHandlers + additionalHandlers {
            handlers[handler.name] = handler
        }
    }

    func handler(named name: String) -> (any MemberFunctionHandler)? {
        handlers[name]
    }

    func register(handler: any MemberFunctionHandler) {
        handlers[handler.name] = handler
    }

    func call(
        name: String,
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let handler = handler(named: name) else {
            throw SwiftUIEvaluatorError.unsupportedExpression("Unsupported member function \(name)")
        }
        return try handler.call(
            baseValue: baseValue,
            arguments: arguments,
            context: context
        )
    }

    private static var defaultHandlers: [any MemberFunctionHandler] {
        modifierHandlers + collectionHandlers
    }

    private static var modifierHandlers: [any MemberFunctionHandler] {
        [
            BackgroundModifierHandler(),
            CornerRadiusModifierHandler(),
            FontModifierHandler(),
            ForegroundStyleModifierHandler(),
            FrameModifierHandler(),
            ImageScaleModifierHandler(),
            OpacityModifierHandler(),
            OverlayModifierHandler(),
            PaddingModifierHandler(),
            ShadowModifierHandler()
        ]
    }

    private static var collectionHandlers: [any MemberFunctionHandler] {
        [
            ContainsMemberFunctionHandler(),
            ShuffleMemberFunctionHandler(),
            ShuffledMemberFunctionHandler()
        ]
    }
    func hasHandler(named name: String) -> Bool {
        handler(named: name) != nil
    }
}

import SwiftSyntax

public protocol MemberFunctionHandler {
    var name: String { get }
    func call(
        resolver: ExpressionResolver,
        baseValue: SwiftValue,
        arguments: LabeledExprListSyntax,
        scope: [String: SwiftValue],
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue?
}

final class MemberFunctionRegistry {
    private var handlers: [String: any MemberFunctionHandler]

    init(additionalHandlers: [any MemberFunctionHandler] = []) {
        handlers = Self.makeLookup(
            defaults: Self.defaultHandlers,
            additional: additionalHandlers
        )
    }

    func handler(named name: String) -> (any MemberFunctionHandler)? {
        handlers[name]
    }

    private static var defaultHandlers: [any MemberFunctionHandler] {
        [
            ContainsMemberFunctionHandler(),
            ShuffleMemberFunctionHandler(),
            ShuffledMemberFunctionHandler()
        ]
    }

    private static func makeLookup(
        defaults: [any MemberFunctionHandler],
        additional: [any MemberFunctionHandler]
    ) -> [String: any MemberFunctionHandler] {
        var lookup: [String: any MemberFunctionHandler] = [:]
        for handler in defaults + additional {
            lookup[handler.name] = handler
        }
        return lookup
    }
}

private struct ContainsMemberFunctionHandler: MemberFunctionHandler {
    let name = "contains"

    func call(
        resolver: ExpressionResolver,
        baseValue: SwiftValue,
        arguments: LabeledExprListSyntax,
        scope: [String: SwiftValue],
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        try resolver.resolveContainsCall(
            baseValue: baseValue,
            arguments: arguments,
            scope: scope,
            context: context
        )
    }
}

private struct ShuffleMemberFunctionHandler: MemberFunctionHandler {
    let name = "shuffle"

    func call(
        resolver: ExpressionResolver,
        baseValue: SwiftValue,
        arguments: LabeledExprListSyntax,
        scope: [String: SwiftValue],
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        try resolver.resolveShuffleCall(
            baseValue: baseValue,
            arguments: arguments
        )
    }
}

private struct ShuffledMemberFunctionHandler: MemberFunctionHandler {
    let name = "shuffled"

    func call(
        resolver: ExpressionResolver,
        baseValue: SwiftValue,
        arguments: LabeledExprListSyntax,
        scope: [String: SwiftValue],
        context: (any SwiftUIEvaluatorContext)?
    ) throws -> SwiftValue? {
        try resolver.resolveShuffledCall(
            baseValue: baseValue,
            arguments: arguments
        )
    }
}

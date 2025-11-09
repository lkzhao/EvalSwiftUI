import SwiftUI

struct CornerRadiusModifierHandler: MemberFunctionHandler {
    let name = "cornerRadius"

    func call(
        baseValue: SwiftValue?,
        arguments: [ResolvedArgument],
        context: any SwiftUIEvaluatorContext
    ) throws -> SwiftValue {
        guard let baseView = baseValue?.asAnyView() else {
            throw SwiftUIEvaluatorError.invalidArguments("cornerRadius modifier requires a view receiver.")
        }
        guard let radiusArgument = arguments.first(where: { $0.label == nil }) ?? arguments.first(where: { $0.label == "radius" }) else {
            throw SwiftUIEvaluatorError.invalidArguments("cornerRadius requires a radius argument.")
        }
        let unlabeledCount = arguments.filter { $0.label == nil }.count
        guard unlabeledCount <= 1 else {
            throw SwiftUIEvaluatorError.invalidArguments("cornerRadius accepts exactly one unlabeled radius argument.")
        }
        guard arguments.allSatisfy({ argument in
            guard let label = argument.label else { return true }
            return label == "radius" || label == "antialiased"
        }) else {
            throw SwiftUIEvaluatorError.invalidArguments("cornerRadius received unsupported labeled arguments.")
        }
        let radius = try radiusArgument.value.asCGFloat()
        let antialiased = try decodeAntialiased(from: arguments.first { $0.label == "antialiased" }?.value)
        return .view(AnyView(baseView.cornerRadius(radius, antialiased: antialiased)))
    }

    private func decodeAntialiased(from value: SwiftValue?) throws -> Bool {
        guard let value else { return true }
        return try value.asBool()
    }
}

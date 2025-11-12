import SwiftUI

public struct ButtonRuntimeViewBuilder: RuntimeViewBuilder {
    public let typeName = "Button"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        module: RuntimeModule,
        scope: RuntimeScope
    ) throws -> AnyView {
        var actionFunction: CompiledFunction?
        var labelFunction: CompiledFunction?
        var title: String?

        for parameter in arguments {
            if parameter.label == "action", case .function(let function) = parameter.value {
                actionFunction = function
                continue
            }

            if parameter.label == "label", case .function(let function) = parameter.value {
                labelFunction = function
                continue
            }

            switch parameter.value {
            case .string(let string) where title == nil:
                title = string
            case .function(let function):
                if actionFunction == nil {
                    actionFunction = function
                } else if labelFunction == nil {
                    labelFunction = function
                }
            default:
                continue
            }
        }

        guard let actionFunction else {
            throw RuntimeError.invalidViewArgument("Button requires an action closure.")
        }

        let action = RuntimeButtonAction(function: actionFunction, scope: scope)

        if let labelFunction = labelFunction {
            let labelViews = try StatementInterpreter(module: module, scope: scope)
                .executeAndCollectRuntimeViews(statements: labelFunction.ir.body)
            guard labelViews.count == 1, let runtimeView = labelViews.first else {
                throw RuntimeError.invalidViewArgument("Button label closures must return exactly one view.")
            }
            let label = try module.makeSwiftUIView(
                typeName: runtimeView.typeName,
                arguments: runtimeView.arguments,
                scope: scope
            )
            return AnyView(Button(action: action.perform) {
                label
            })
        }

        guard let title else {
            throw RuntimeError.invalidViewArgument("Button requires a title string when no label closure is provided.")
        }

        return AnyView(Button(action: action.perform) {
            Text(title)
        })
    }
}

private final class RuntimeButtonAction {
    private let function: CompiledFunction
    private let scope: RuntimeScope

    init(function: CompiledFunction, scope: RuntimeScope) {
        self.function = function
        self.scope = scope
    }

    func perform() {
        _ = try? function.invoke(arguments: [], scope: scope)
    }
}

import SwiftUI

extension SwiftValue {
    func boolBinding(description: String) throws -> Binding<Bool> {
        guard case .binding(let bindingValue) = self else {
            throw SwiftUIEvaluatorError.invalidArguments("\(description) requires a binding value (use $ to reference @State), received \(typeDescription).")
        }
        let initialStorage = bindingValue.read()
        guard let _ = initialStorage.boolStorageValue else {
            throw SwiftUIEvaluatorError.invalidArguments("\(description) must be backed by a boolean @State variable.")
        }
        let writesOptional = initialStorage.isOptional
        return Binding(
            get: {
                guard let current = bindingValue.read().boolStorageValue else {
                    assertionFailure("Boolean binding resolved to a non-boolean value.")
                    return false
                }
                return current
            },
            set: { newValue in
                if writesOptional {
                    bindingValue.write(.optional(.bool(newValue)))
                } else {
                    bindingValue.write(.bool(newValue))
                }
            }
        )
    }
}

private extension SwiftValue {
    var boolStorageValue: Bool? {
        switch resolvingStateReference() {
        case .bool(let value):
            return value
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                return nil
            }
            return unwrapped.boolStorageValue
        default:
            return nil
        }
    }
}

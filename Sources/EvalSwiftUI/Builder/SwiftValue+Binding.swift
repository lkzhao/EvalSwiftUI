import SwiftUI

extension SwiftValue {
    func boolBinding(description: String) throws -> Binding<Bool> {
        guard let _ = boolStorageValue else {
            throw SwiftUIEvaluatorError.invalidArguments("\(description) must be backed by a boolean @State variable.")
        }
        let writesOptional = isOptional
        return Binding(
            get: { [weak self] in
                guard let current = self?.boolStorageValue else {
                    assertionFailure("Boolean binding resolved to a non-boolean value.")
                    return false
                }
                return current
            },
            set: { [weak self] (newValue: Bool) in
                if writesOptional {
                    self?.payload = .optional(.bool(newValue))
                } else {
                    self?.payload = .bool(newValue)
                }
            }
        )
    }
}

private extension SwiftValue {
    var boolStorageValue: Bool? {
        switch payload {
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

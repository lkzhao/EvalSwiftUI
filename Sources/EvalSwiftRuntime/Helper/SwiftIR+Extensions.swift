import Foundation
import EvalSwiftIR

public typealias RuntimeKeyPath = KeyPathIR

private enum PreferredNumericType {
    case int
    case double
}

extension BindingIR {
    func coercedValue(from value: RuntimeValue) -> RuntimeValue {
        guard let preferred = preferredNumericType else {
            return value
        }

        switch preferred {
        case .double:
            if let double = value.asDouble {
                return .double(double)
            }
            return value
        case .int:
            if let int = value.asInt {
                return .int(int)
            }
            return value
        }
    }

    private var preferredNumericType: PreferredNumericType? {
        guard let annotation = type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return nil
        }

        switch annotation {
        case "double":
            return .double
        case "float", "cgfloat":
            return .double
        case "int":
            return .int
        default:
            return nil
        }
    }
}

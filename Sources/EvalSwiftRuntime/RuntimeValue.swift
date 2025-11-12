import Foundation
import EvalSwiftIR

public enum RuntimeValue {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case viewDefinition(CompiledViewDefinition)
    case view(RuntimeView)
    case array([RuntimeValue])
    case function(CompiledFunction)
    case void
}

extension RuntimeValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int(let value):
            return String(value)
        case .double(let number):
            return String(number)
        case .string(let string):
            return string
        case .bool(let bool):
            return String(bool)
        case .viewDefinition:
            return "<ViewDefinition>"
        case .view(let view):
            return String(describing: view)
        case .array(let values):
            return values.map { "\($0)" }.joined(separator: ",")
        case .function:
            return "<Function>"
        case .void:
            return "void"
        }
    }
}

extension RuntimeValue {
    var asString: String? {
        switch self {
        case .string(let string):
            return string
        case .int(let value):
            return String(value)
        case .double(let number):
            return String(number)
        case .bool(let bool):
            return String(bool)
        default:
            return nil
        }
    }

    var asDouble: Double? {
        switch self {
        case .int(let value):
            return Double(value)
        case .double(let number):
            return number
        case .string(let string):
            return Double(string)
        default:
            return nil
        }
    }
}

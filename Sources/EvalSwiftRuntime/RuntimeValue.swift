import Foundation
import EvalSwiftIR

public enum RuntimeValue {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case keyPath(RuntimeKeyPath)
    case viewDefinition(ViewDefinition)
    case viewBuilder(any RuntimeViewBuilder)
    case function(Function)
    case view(RuntimeView)
    case array([RuntimeValue])
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
        case .keyPath:
            return "<KeyPath>"
        case .viewDefinition:
            return "<ViewDefinition>"
        case .viewBuilder(let builder):
            return "<ViewBuilder \(builder.typeName)>"
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

    var asInt: Int? {
        switch self {
        case .int(let value):
            return value
        case .double(let number):
            return Int(number)
        case .string(let string):
            return Int(string)
        case .bool(let bool):
            return bool ? 1 : 0
        default:
            return nil
        }
    }
}

extension RuntimeValue {
    enum RuntimeType: String {
        case int = "Int"
        case double = "Double"
        case string = "String"
        case bool = "Bool"
        case keyPath = "KeyPath"
        case viewDefinition = "ViewDefinition"
        case viewBuilder = "ViewBuilder"
        case view = "RuntimeView"
        case array = "Array"
        case function = "Function"
        case void = "Void"
    }

    var runtimeType: RuntimeType {
        switch self {
        case .int:
            return .int
        case .double:
            return .double
        case .string:
            return .string
        case .bool:
            return .bool
        case .keyPath:
            return .keyPath
        case .viewDefinition:
            return .viewDefinition
        case .viewBuilder:
            return .viewBuilder
        case .view:
            return .view
        case .array:
            return .array
        case .function:
            return .function
        case .void:
            return .void
        }
    }

    var runtimeTypeDescription: String {
        runtimeType.rawValue
    }
}

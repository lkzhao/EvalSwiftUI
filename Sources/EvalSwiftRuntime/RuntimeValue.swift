import Foundation
import EvalSwiftIR

public enum RuntimeValue {
    case number(Double)
    case string(String)
    case bool(Bool)
    case viewDefinition(ViewDefinitionIR)
    case array([RuntimeValue])
    case function(CompiledFunction)
    case void
}

extension RuntimeValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .number(let number):
            return String(number)
        case .string(let string):
            return string
        case .bool(let bool):
            return String(bool)
        case .viewDefinition(let definition):
            return "<ViewDefinition: \(definition.name)>"
        case .array(let values):
            return values.map { "\($0)" }.joined(separator: ",")
        case .function(let function):
            return "<Function: \(function.ir.name)>"
        case .void:
            return "void"
        }
    }
}

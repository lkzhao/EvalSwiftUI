import SwiftUI

extension SwiftValue {
    func asCGFloat() throws -> CGFloat {
        guard let resolved = unwrappedOptional() else {
            throw SwiftUIEvaluatorError.invalidArguments("Unexpected nil optional when decoding numeric value.")
        }

        switch resolved.payload {
        case .number(let number):
            return CGFloat(number)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Expected numeric value, received \(resolved.typeDescription).")
        }
    }

    func asDouble() throws -> Double {
        guard let resolved = unwrappedOptional() else {
            throw SwiftUIEvaluatorError.invalidArguments("Unexpected nil optional when decoding numeric value.")
        }

        switch resolved.payload {
        case .number(let number):
            return number
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Expected numeric value, received \(resolved.typeDescription).")
        }
    }

    func asBool() throws -> Bool {
        guard let resolved = unwrappedOptional() else {
            throw SwiftUIEvaluatorError.invalidArguments("Unexpected nil optional when decoding boolean value.")
        }

        switch resolved.payload {
        case .bool(let flag):
            return flag
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Expected boolean value, received \(resolved.typeDescription).")
        }
    }

    func asInt() throws -> Int {
        guard let resolved = unwrappedOptional() else {
            throw SwiftUIEvaluatorError.invalidArguments("Unexpected nil optional when decoding numeric value.")
        }

        switch resolved.payload {
        case .number(let number):
            guard number.truncatingRemainder(dividingBy: 1) == 0 else {
                throw SwiftUIEvaluatorError.invalidArguments("Expected whole number value, received decimal \(number).")
            }
            return Int(number)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Expected numeric value, received \(resolved.typeDescription).")
        }
    }

    func asString() throws -> String {
        guard let resolved = unwrappedOptional() else {
            throw SwiftUIEvaluatorError.invalidArguments("Unexpected nil optional when decoding string value.")
        }

        switch resolved.payload {
        case .string(let string):
            return string
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Expected string value, received \(resolved.typeDescription).")
        }
    }

    func asAnyView() -> AnyView? {
        guard let resolved = unwrappedOptional() else {
            return nil
        }

        if case .view(let view) = resolved.payload {
            return view
        }
        return nil
    }

    func asArray() throws -> [SwiftValue] {
        guard let resolved = unwrappedOptional() else {
            throw SwiftUIEvaluatorError.invalidArguments("Array operations cannot operate on nil optional values.")
        }

        switch resolved.payload {
        case .array(let elements):
            return elements
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Array operations require an array value.")
        }
    }

    func asRange() throws -> RangeValue {
        guard let resolved = unwrappedOptional() else {
            throw SwiftUIEvaluatorError.invalidArguments("Range operations cannot operate on nil optional values.")
        }

        switch resolved.payload {
        case .range(let value):
            return value
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Range operations require a range literal.")
        }
    }

    func asSequence() throws -> [SwiftValue] {
        guard let resolved = unwrappedOptional() else {
            throw SwiftUIEvaluatorError.invalidArguments("Sequence operations cannot operate on nil optional values.")
        }

        switch resolved.payload {
        case .array(let elements):
            return elements
        case .range(let rangeValue):
            return rangeValue.elements().map { .number(Double($0)) }
        default:
            throw SwiftUIEvaluatorError.invalidArguments("Sequence operations require an array or range value.")
        }
    }
}

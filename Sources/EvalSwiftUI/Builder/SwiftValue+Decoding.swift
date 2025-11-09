import SwiftUI

extension SwiftValue {
    func asCGFloat(description: String) throws -> CGFloat {
        switch resolvingStateReference() {
        case .number(let number):
            return CGFloat(number)
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("\(description) cannot be nil.")
            }
            return try unwrapped.asCGFloat(description: description)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("\(description) must be numeric.")
        }
    }

    func asDouble(description: String) throws -> Double {
        switch resolvingStateReference() {
        case .number(let number):
            return number
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("\(description) cannot be nil.")
            }
            return try unwrapped.asDouble(description: description)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("\(description) must be numeric.")
        }
    }

    func asBool(description: String) throws -> Bool {
        switch resolvingStateReference() {
        case .bool(let flag):
            return flag
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("\(description) cannot be nil.")
            }
            return try unwrapped.asBool(description: description)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("\(description) must be a boolean value.")
        }
    }

    func asInt(description: String) throws -> Int {
        switch resolvingStateReference() {
        case .number(let number):
            guard number.truncatingRemainder(dividingBy: 1) == 0 else {
                throw SwiftUIEvaluatorError.invalidArguments("\(description) must resolve to whole numbers.")
            }
            return Int(number)
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("\(description) cannot be nil.")
            }
            return try unwrapped.asInt(description: description)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("\(description) must resolve to numeric values.")
        }
    }
}

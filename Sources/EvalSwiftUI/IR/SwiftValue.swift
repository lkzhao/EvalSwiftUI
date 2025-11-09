//
//  SwiftValue.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/8/25.
//

import SwiftUI

public final class SwiftValue: @unchecked Sendable {
    public enum Payload {
        case string(String)
        case memberAccess([String])
        case number(Double)
        case functionCall(FunctionCallValue)
        case bool(Bool)
        case optional(SwiftValue?)
        case array([SwiftValue])
        case range(RangeValue)
        case keyPath(KeyPathValue)
        case dictionary([String: SwiftValue])
        case closure(ResolvedClosure)
        case view(AnyView)
    }

    init(_ payload: Payload) {
        self.payload = payload
    }

    @Published
    var payload: Payload

    func mutatePayload(_ transform: (inout Payload) -> Void) {
        transform(&payload)
    }

    func copy() -> SwiftValue {
        SwiftValue(payload.deepCopy())
    }

    func replace(with value: SwiftValue) {
        payload = value.payload.deepCopy()
    }
}

public struct FunctionCallValue {
    public let name: [String]
    public let arguments: [ResolvedArgument]
}

public struct KeyPathValue {
    public let components: [String]
}

public struct RangeValue {
    public enum Style {
        case halfOpen
        case closed
    }

    public let lowerBound: Int
    public let upperBound: Int
    public let style: Style
}

extension RangeValue {
    func elements() -> [Int] {
        switch style {
        case .halfOpen:
            if lowerBound >= upperBound {
                return []
            }
            return Array(lowerBound..<upperBound)
        case .closed:
            return Array(lowerBound...upperBound)
        }
    }

    func contains(_ value: Int) -> Bool {
        switch style {
        case .halfOpen:
            return value >= lowerBound && value < upperBound
        case .closed:
            return value >= lowerBound && value <= upperBound
        }
    }
}

extension SwiftValue {
    var resolvedClosure: ResolvedClosure? {
        if case let .closure(value) = payload {
            return value
        }
        return nil
    }
}

extension SwiftValue {
    var typeDescription: String {
        switch payload {
        case .string:
            return "string"
        case .memberAccess:
            return "member reference"
        case .number:
            return "number"
        case .functionCall:
            return "function call"
        case .bool:
            return "bool"
        case .optional:
            return "optional"
        case .array:
            return "array"
        case .range:
            return "range"
        case .keyPath:
            return "keyPath"
        case .dictionary:
            return "dictionary"
        case .closure:
            return "closure"
        case .view:
            return "view"
        }
    }

    func unwrappedOptional() -> SwiftValue? {
        switch payload {
        case .optional(let wrapped):
            guard let wrapped else { return nil }
            return wrapped.unwrappedOptional()
        default:
            return self
        }
    }

    var isOptional: Bool {
        if case .optional = payload {
            return true
        }
        return false
    }

    func equals(_ other: SwiftValue) -> Bool {
        switch (payload, other.payload) {
        case (.string(let left), .string(let right)):
            return left == right
        case (.number(let left), .number(let right)):
            return left == right
        case (.bool(let left), .bool(let right)):
            return left == right
        case (.memberAccess(let left), .memberAccess(let right)):
            return memberPathsEqual(left, right)
        case (.optional(let left), .optional(let right)):
            switch (left?.unwrappedOptional(), right?.unwrappedOptional()) {
            case (nil, nil):
                return true
            case let (lhsValue?, rhsValue?):
                return lhsValue.equals(rhsValue)
            default:
                return false
            }
        case (.optional(let wrapped), _):
            if let unwrapped = wrapped?.unwrappedOptional() {
                return unwrapped.equals(other)
            }
            return false
        case (_, .optional):
            return other.equals(self)
        case (.closure, .closure):
            return false
        case (.view, .view):
            return false
        default:
            return false
        }
    }

}

private func memberPathsEqual(_ lhs: [String], _ rhs: [String]) -> Bool {
    if lhs == rhs {
        return true
    }

    guard let lhsLast = lhs.last, let rhsLast = rhs.last else {
        return false
    }

    return lhsLast == rhsLast
}


extension SwiftValue.Payload {
    fileprivate func deepCopy() -> SwiftValue.Payload {
        switch self {
        case .string(let string):
            return .string(string)
        case .memberAccess(let path):
            return .memberAccess(path)
        case .number(let number):
            return .number(number)
        case .functionCall(let value):
            return .functionCall(value)
        case .bool(let flag):
            return .bool(flag)
        case .optional(let wrapped):
            return .optional(wrapped?.copy())
        case .array(let values):
            return .array(values.map { $0.copy() })
        case .range(let range):
            return .range(range)
        case .keyPath(let keyPath):
            return .keyPath(keyPath)
        case .dictionary(let dictionary):
            var copy: [String: SwiftValue] = [:]
            for (key, value) in dictionary {
                copy[key] = value.copy()
            }
            return .dictionary(copy)
        case .closure(let closure):
            return .closure(closure)
        case .view(let view):
            return .view(view)
        }
    }
}

extension SwiftValue {
    static func string(_ value: String) -> SwiftValue { SwiftValue(.string(value)) }
    static func memberAccess(_ value: [String]) -> SwiftValue { SwiftValue(.memberAccess(value)) }
    static func number(_ value: Double) -> SwiftValue { SwiftValue(.number(value)) }
    static func functionCall(_ value: FunctionCallValue) -> SwiftValue { SwiftValue(.functionCall(value)) }
    static func bool(_ value: Bool) -> SwiftValue { SwiftValue(.bool(value)) }
    static func optional(_ value: SwiftValue?) -> SwiftValue { SwiftValue(.optional(value)) }
    static func array(_ value: [SwiftValue]) -> SwiftValue { SwiftValue(.array(value)) }
    static func range(_ value: RangeValue) -> SwiftValue { SwiftValue(.range(value)) }
    static func keyPath(_ value: KeyPathValue) -> SwiftValue { SwiftValue(.keyPath(value)) }
    static func dictionary(_ value: [String: SwiftValue]) -> SwiftValue { SwiftValue(.dictionary(value)) }
    static func closure(_ value: ResolvedClosure) -> SwiftValue { SwiftValue(.closure(value)) }
    static func view(_ value: AnyView) -> SwiftValue { SwiftValue(.view(value)) }
}

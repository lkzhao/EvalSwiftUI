//
//  RuntimeScope.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/11/25.
//

public protocol RuntimeScope: AnyObject, CustomStringConvertible {
    var storage: [String: RuntimeValue] { get }
    var parent: RuntimeScope? { get }
    // TODO: define/set/get should receive a type to distinguish between same variable names with different types
    func define(_ name: String, value: RuntimeValue)
    func set(_ name: String, value: RuntimeValue)
    func get(_ name: String) -> RuntimeValue?
}

extension RuntimeScope {
    public var description: String {
        var desc = "\(type(of: self))(storage: \(storage)"
        if let parent = parent {
            desc += ", parent: \(parent)"
        }
        desc += ")"
        return desc
    }
    public var instance: RuntimeInstance? {
        guard let instance = self as? RuntimeInstance else {
            return parent?.instance
        }
        return instance
    }
    public func callMethod(_ name: String, arguments: [RuntimeArgument] = []) throws -> RuntimeValue? {
        guard let value = get(name), case .function(let function) = value else {
            throw RuntimeError.unknownFunction(name)
        }
        return try function.invoke(arguments: arguments, scope: self)
    }
}

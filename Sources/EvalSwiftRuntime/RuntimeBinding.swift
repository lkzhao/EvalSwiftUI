import Foundation

public struct RuntimeBinding {
    private let getter: () throws -> RuntimeValue
    private let setter: (RuntimeValue) throws -> Void

    public init(getter: @escaping () throws -> RuntimeValue, setter: @escaping (RuntimeValue) throws -> Void) {
        self.getter = getter
        self.setter = setter
    }

    public func get() throws -> RuntimeValue {
        try getter()
    }

    public func set(_ value: RuntimeValue) throws {
        try setter(value)
    }
}

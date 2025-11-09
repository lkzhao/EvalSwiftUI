import Foundation

final class RuntimeScope {
    private var storage: [String: RuntimeValue] = [:]
    private let parent: RuntimeScope?

    init(parent: RuntimeScope? = nil) {
        self.parent = parent
    }

    func set(_ name: String, value: RuntimeValue) {
        storage[name] = value
    }

    func get(_ name: String) -> RuntimeValue? {
        if let value = storage[name] {
            return value
        }
        return parent?.get(name)
    }
}

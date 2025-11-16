import Foundation

struct CountMethodBuilder: RuntimeMethodBuilder {
    let name = "count"
    let supportsMemberAccess = true
    let definitions: [RuntimeMethodDefinition] = [
        RuntimeValueMethodDefinition(parameters: []) { base, _, _ in
            guard let count = base.countValue else {
                throw RuntimeError.invalidArgument("count is not supported on \(base.valueType)")
            }
            return .int(count)
        }
    ]
}

struct IsEmptyMethodBuilder: RuntimeMethodBuilder {
    let name = "isEmpty"
    let supportsMemberAccess = true
    let definitions: [RuntimeMethodDefinition] = [
        RuntimeValueMethodDefinition(parameters: []) { base, _, _ in
            guard let isEmpty = base.isEmptyValue else {
                throw RuntimeError.invalidArgument("isEmpty is not supported on \(base.valueType)")
            }
            return .bool(isEmpty)
        }
    ]
}

struct ToggleMethodBuilder: RuntimeMethodBuilder {
    let name = "toggle"
    let definitions: [RuntimeMethodDefinition] = [
        RuntimeValueMethodDefinition(parameters: []) { base, setter, _, _ in
            if let binding = base.asBinding {
                let current = try binding.get()
                guard let toggled = current.toggledValue else {
                    throw RuntimeError.invalidArgument("toggle() is only supported on Bool values.")
                }
                try binding.set(toggled)
                return .void
            }
            guard let toggled = base.toggledValue else {
                throw RuntimeError.invalidArgument("toggle() is only supported on Bool values.")
            }
            guard let setter else {
                throw RuntimeError.invalidArgument("toggle() requires a mutable receiver.")
            }
            try setter(toggled)
            return .void
        }
    ]
}

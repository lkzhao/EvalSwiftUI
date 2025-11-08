final class RuntimeStateStore {
    final class Slot {
        var value: SwiftValue

        init(value: SwiftValue) {
            self.value = value
        }
    }

    private var slots: [String: Slot] = [:]

    func makeState(identifier: String, initialValue: SwiftValue) -> StateReference {
        if let existing = slots[identifier] {
            existing.value = initialValue
            return StateReference(identifier: identifier, slot: existing)
        }
        let slot = Slot(value: initialValue)
        slots[identifier] = slot
        return StateReference(identifier: identifier, slot: slot)
    }

    func reference(for identifier: String) -> StateReference? {
        guard let slot = slots[identifier] else {
            return nil
        }
        return StateReference(identifier: identifier, slot: slot)
    }

    func reset() {
        slots.removeAll()
    }
}

public struct StateReference {
    let identifier: String
    fileprivate let slot: RuntimeStateStore.Slot

    func read() -> SwiftValue {
        slot.value
    }

    func write(_ value: SwiftValue) {
        slot.value = value
    }
}

public struct BindingValue {
    let reference: StateReference

    func read() -> SwiftValue {
        reference.read()
    }

    func write(_ value: SwiftValue) {
        reference.write(value)
    }
}

import Foundation

public final class RuntimeStateStore {
    final class Slot {
        var value: SwiftValue

        init(value: SwiftValue) {
            self.value = value
        }
    }

    private var slots: [String: Slot] = [:]
    var onChange: (@MainActor () -> Void)?

    func makeState(identifier: String, initialValue: SwiftValue) -> StateReference {
        if let existing = slots[identifier] {
            return StateReference(identifier: identifier, slot: existing, store: self)
        }
        let slot = Slot(value: initialValue)
        slots[identifier] = slot
        return StateReference(identifier: identifier, slot: slot, store: self)
    }

    func reference(for identifier: String) -> StateReference? {
        guard let slot = slots[identifier] else {
            return nil
        }
        return StateReference(identifier: identifier, slot: slot, store: self)
    }

    func reset() {
        slots.removeAll()
        onChange = nil
    }

    func stateDidMutate() {
        guard let onChange else { return }
        Task { @MainActor in
            onChange()
        }
    }
}

public struct StateReference {
    let identifier: String
    fileprivate let slot: RuntimeStateStore.Slot
    fileprivate unowned let store: RuntimeStateStore

    func read() -> SwiftValue {
        slot.value
    }

    func write(_ value: SwiftValue) {
        slot.value = value
        store.stateDidMutate()
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

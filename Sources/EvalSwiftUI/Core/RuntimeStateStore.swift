import Combine

public final class RuntimeStateStore {
    final class Slot {
        let value: SwiftValue
        private weak var store: RuntimeStateStore?
        private var observationToken: AnyCancellable?

        init(value: SwiftValue, identifier: String, store: RuntimeStateStore) {
            self.value = value
            self.store = store
            value.markAsState(identifier: identifier)
            observationToken = value.$payload.sink { [weak store] _ in
                store?.stateDidMutate()
            }
        }
    }

    private var slots: [String: Slot] = [:]
    var onChange: (@MainActor () -> Void)?

    func makeState(identifier: String, initialValue: SwiftValue) -> StateReference {
        if let existing = slots[identifier] {
            return StateReference(identifier: identifier, slot: existing)
        }
        let slotValue = initialValue.copy()
        let slot = Slot(value: slotValue, identifier: identifier, store: self)
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
        onChange = nil
    }

    func stateDidMutate() {
        guard let onChange else { return }
        Task { @MainActor in
            onChange()
        }
    }

    func identifiers() -> [String] {
        Array(slots.keys)
    }
}

public struct StateReference {
    let identifier: String
    fileprivate let slot: RuntimeStateStore.Slot

    func read() -> SwiftValue {
        slot.value
    }

    func write(_ value: SwiftValue) {
        slot.value.replace(with: value)
    }

    func mutate(_ mutate: (SwiftValue) -> Void) {
        mutate(slot.value)
    }

    fileprivate var storage: SwiftValue { slot.value }
}

public struct BindingValue: @unchecked Sendable {
    let identifier: String
    private let storage: SwiftValue

    init(reference: StateReference) {
        self.identifier = reference.identifier
        self.storage = reference.storage
    }

    func read() -> SwiftValue {
        storage
    }

    func write(_ value: SwiftValue) {
        storage.replace(with: value)
    }

    func mutate(_ mutate: (SwiftValue) -> Void) {
        mutate(storage)
    }
}

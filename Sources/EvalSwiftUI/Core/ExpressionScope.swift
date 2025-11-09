import Foundation

/// Wraps lexical values captured while lowering syntax so layers can reason about
/// mutability/origin without passing raw dictionaries around.
struct ExpressionScope: ExpressibleByDictionaryLiteral {
    enum Origin {
        case local
        case captured
        case external
    }

    private struct Entry {
        var value: SwiftValue
        var origin: Origin
        var isMutable: Bool
    }

    private var storage: [String: Entry] = [:]

    init(values: [String: SwiftValue] = [:], origin: Origin = .local, isMutable: Bool = true) {
        for (key, value) in values {
            storage[key] = Entry(value: value, origin: origin, isMutable: isMutable)
        }
    }

    init(dictionaryLiteral elements: (String, SwiftValue)...) {
        for (key, value) in elements {
            storage[key] = Entry(value: value, origin: .local, isMutable: true)
        }
    }

    subscript(key: String) -> SwiftValue? {
        get { storage[key]?.value }
        set {
            if let newValue {
                storage[key] = Entry(value: newValue, origin: storage[key]?.origin ?? .local, isMutable: true)
            } else {
                storage.removeValue(forKey: key)
            }
        }
    }

    mutating func set(_ value: SwiftValue, for key: String, origin: Origin = .local, mutable: Bool = true) {
        storage[key] = Entry(value: value, origin: origin, isMutable: mutable)
    }

    func merged(_ other: ExpressionScope, replaceExisting: Bool = true) -> ExpressionScope {
        var merged = self
        merged.merge(other, replaceExisting: replaceExisting)
        return merged
    }

    mutating func merge(_ other: ExpressionScope, replaceExisting: Bool = true) {
        for (key, entry) in other.storage {
            if storage[key] != nil && !replaceExisting {
                continue
            }
            storage[key] = entry
        }
    }

    func merging(_ other: ExpressionScope, combine: (_ current: SwiftValue, _ new: SwiftValue) -> SwiftValue) -> ExpressionScope {
        var merged = self
        merged.merge(other, combine: combine)
        return merged
    }

    mutating func merge(_ other: ExpressionScope, combine: (_ current: SwiftValue, _ new: SwiftValue) -> SwiftValue) {
        for (key, entry) in other.storage {
            if let existing = storage[key] {
                let combined = combine(existing.value, entry.value)
                storage[key] = Entry(value: combined, origin: entry.origin, isMutable: entry.isMutable)
            } else {
                storage[key] = entry
            }
        }
    }

    func asDictionary() -> [String: SwiftValue] {
        storage.mapValues { $0.value }
    }

    static var empty: ExpressionScope { ExpressionScope(values: [:]) }
}

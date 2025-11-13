
# TODO
- [ ] Implement full keypath support


Right now all SwiftUI types like Color, Font, Alignment, Image.Scale are also defined on the global scope. We should allow parameter to parse from its own type instead of putting everything global (which might cause conflict).
Maybe make each param value not a concrete RuntimeValue, but a key path or member access so that each view or modifier builder can realize the value itself from type. 
Also replace these lines from SwiftIRParser.swift
```swift
let trimmed = expr.trimmedDescription
if trimmed.hasPrefix("."), trimmed.count > 1 {
    let nextIndex = trimmed.index(after: trimmed.startIndex)
    let identifier = String(trimmed[nextIndex...])
    return .identifier(identifier)
}
```
These lines makes all `.xxxx` as identifiers, they should be member probably.


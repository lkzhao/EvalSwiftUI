# TODO

- [x] Implement baseline keypath support (member access, optional chaining, force unwraps)
- [x] Parse key paths that specify explicit roots or subscript components (e.g. `\Todo.id`, `\.items[0].label`)
    - [x] Extend `KeyPathIR` to capture type roots and subscript arguments
    - [x] Teach the parser to surface those components (detect literal indices, labels)
    - [x] Add runtime evaluation for array subscripts and root lookups
    - [ ] Extend subscript evaluation to dictionary lookups once broader Hashable support lands
    - [x] Snapshot tests covering `\.items[0].id`, `\TodoItem.id`, and optional chaining combos
- [ ] Allow `ForEach(id:)` to accept Hashable values beyond primitives (UUID/custom structs)
    - [ ] Surface `UUID`, `Date`, and other Foundation literals as Hashable runtime values
    - [ ] Detect `Identifiable.id` stored on `RuntimeInstance` and forward to `AnyHashable`
    - [ ] Provide diagnostics when the resolved value is an instance but `Hashable` conformance is missing
- [ ] Implement additional shape builders (Circle, Capsule, Rectangle, etc.) that emit `.shape(AnyShape)`
- [ ] Add modifier builders for `border`, `clipShape`, `mask`, and `blendMode`
- [ ] Support gradient ShapeStyles (LinearGradient, AngularGradient, RadialGradient builders plus Gradient parsing)
- [ ] Extend literal parsing for assets/hex so `Color(uiColor:)`-style expressions work inside evaluated snippets
- [ ] Introduce stateful modifiers like `animation`, `transition`, and `onTapGesture`

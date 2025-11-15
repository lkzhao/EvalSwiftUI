# TODO

- [x] Implement baseline keypath support (member access, optional chaining, force unwraps)
- [ ] Parse key paths that specify explicit roots or subscript components (e.g. `\Todo.id`, `\.items[0].label`)
- [ ] Allow `ForEach(id:)` to accept Hashable values beyond primitives (UUID/custom structs)
- [ ] Implement additional shape builders (Circle, Capsule, Rectangle, etc.) that emit `.shape(AnyShape)`
- [ ] Add modifier builders for `border`, `clipShape`, `mask`, and `blendMode`
- [ ] Support gradient ShapeStyles (LinearGradient, AngularGradient, RadialGradient builders plus Gradient parsing)
- [ ] Extend literal parsing for assets/hex so `Color(uiColor:)`-style expressions work inside evaluated snippets
- [ ] Introduce stateful modifiers like `animation`, `transition`, and `onTapGesture`

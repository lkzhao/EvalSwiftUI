# EvalSwiftUI TODO

- [x] Build IR layer that flattens chained member accesses into a `ViewNode` + `ModifierNode`s.
- [x] Create a tiny expression evaluator that lowers SwiftSyntax expressions to typed `SwiftValue`s (strings, member paths, numbers-as-needed).
- [x] Introduce registry-driven view/modifier builders so new SwiftUI features can plug in without touching the evaluator core.
- [x] Support stack alignment and spacing parameters in view builders.
- [x] Expand modifier argument decoding for `foregroundStyle`, `font`, and `padding`.
- [x] Implement `frame` modifier with configurable parameters.
- [x] Support simple array literals in expression evaluation.
- [x] Support range expressions for repeatable data.
- [x] Render `ForEach` nodes given literal data sources.
- [x] Allow `ForEach` to honor explicit `id:` arguments such as `\.self`.
- [x] Support shorthand closure parameters (e.g. `$0`) in content builders.
- [x] Ship a `ZStackViewBuilder` (with alignment decoding) and register it in `ViewRegistry` so layered layouts render just like stacks already do.
- [x] Add a `SpacerViewBuilder` that understands optional `minLength` arguments to make horizontal/vertical stacks match typical SwiftUI spacing scenarios.
- [x] Introduce `background`/`overlay` modifier builders capable of consuming `ViewContent` closures, enabling decorated views without hand-written custom modifiers.
- [ ] Teach `ViewNodeBuilder` how to lower `switch` statements (value + pattern cases) into child nodes so control flow parity goes beyond simple `if` expressions.

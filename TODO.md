# EvalSwiftUI TODO

- [x] Build IR layer that flattens chained member accesses into a `ViewNode` + `ModifierNode`s.
- [x] Create a tiny expression evaluator that lowers SwiftSyntax expressions to typed `SwiftValue`s (strings, member paths, numbers-as-needed).
- [x] Introduce registry-driven view/modifier builders so new SwiftUI features can plug in without touching the evaluator core.
- [ ] Support stack alignment and spacing parameters in view builders.
- [ ] Expand modifier argument decoding for `foregroundStyle`, `font`, and `padding`.
- [ ] Implement `frame` modifier with configurable parameters.

# EvalSwiftUI TODO

- [x] Build IR layer that flattens chained member accesses into a `ViewNode` + `ModifierNode`s.
- [x] Create a tiny expression evaluator that lowers SwiftSyntax expressions to typed `SwiftValue`s (strings, member paths, numbers-as-needed).
- [x] Introduce registry-driven view/modifier builders so new SwiftUI features can plug in without touching the evaluator core.
- [ ] Expand argument decoding helpers (e.g., colors, numbers, EdgeInsets) to unlock richer modifier support.
- [ ] Add more sample programs + snapshot-style tests that prove composed views render as expected.

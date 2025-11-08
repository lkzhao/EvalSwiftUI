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
- [x] Teach `ViewNodeBuilder` how to lower `switch` statements (value + pattern cases) into child nodes so control flow parity goes beyond simple `if` expressions.
- [x] Expand `ExpressionResolver.resolveExpression` (Sources/EvalSwiftUI/Core/ExpressionResolver.swift) so `SequenceExprSyntax` nodes that represent binary operators can collapse into concrete values—e.g. evaluate `name + "!"` into `.string` and `width * 2` / `spacing - 4` into `.number`—instead of throwing `unsupportedExpression`.
- [x] Add comparison and logical operator support (==, !=, <, >, <=, >=, &&, ||) to the same resolver so `if count > 3`, `if isEnabled && hasAccess`, and switch `where` clauses can resolve to `.bool` without requiring precomputed literals.
- [x] Handle unary operators and coalescing in `ExpressionResolver` to cover patterns like `!isHidden`, `-offset`, and `label ?? "Guest"`, which all currently fail because prefix / nil-coalescing expressions never produce a `SwiftValue`.
- [x] Teach the resolver how to evaluate simple member function calls on literals—starting with `(0..<limit).contains(index)` and `items.contains(userId)` by recognizing range/array bases and returning `.bool`—so control flow can lean on the same helpers developers use in regular SwiftUI.

## Stateful SwiftUI runtime

- [ ] Allow `SwiftUIEvaluator` to process leading statements (e.g. `@State var count = 0`) before the root view expression so state declarations are captured instead of rejected.
- [ ] Introduce a runtime state store (likely an `ObservableObject`) that exposes identifier lookups/mutations and update `SwiftValue` to represent bindings/mutable references.
- [ ] Teach `ExpressionResolver` and `ViewNodeBuilder` to recognize assignment operators (`=`, `+=`, etc.) and route writes through the new state store rather than treating every expression as immutable.
- [ ] Differentiate between view-producing closures and action closures so builders like `Button` can run imperative statements inside trailing closures.
- [ ] Add a `ButtonViewBuilder` that wires label/content closures plus actions into a real `SwiftUI.Button`, using bindings from the runtime store when needed.
- [ ] Wrap evaluations in a SwiftUI container view that re-renders when the state store changes, and cover the stateful counter scenario in tests (success + snapshot).

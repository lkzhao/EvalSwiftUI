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

- [x] Allow `SwiftUIEvaluator` to process leading statements (e.g. `@State var count = 0`) before the root view expression so state declarations are captured instead of rejected.
- [x] Introduce a runtime state store (likely an `ObservableObject`) that exposes identifier lookups/mutations and update `SwiftValue` to represent bindings/mutable references.
- [x] Teach `ExpressionResolver` and `ViewNodeBuilder` to recognize assignment operators (`=`, `+=`, etc.) and route writes through the new state store rather than treating every expression as immutable.
- [x] Differentiate between view-producing closures and action closures so builders like `Button` can run imperative statements inside trailing closures.
- [x] Add a `ButtonViewBuilder` that wires label/content closures plus actions into a real `SwiftUI.Button`, using bindings from the runtime store when needed.
- [x] Wrap evaluations in a SwiftUI container view that re-renders when the state store changes, and cover the stateful counter scenario in tests (success + snapshot).

## Next steps

- [x] Surface binding-backed controls by decoding `.binding` values inside view builders (e.g. add a `ToggleViewBuilder` plus a helper that turns `SwiftValue.binding` into `Binding<Bool>` so stateful snippets can flip `@State` flags without manual bridging), and cover the behavior in `SwiftUIEvaluatorStateTests` with a toggle scenario.
- [x] Add a `ScrollViewViewBuilder` that understands axis and indicator arguments so snippets that wrap `ForEach` in `ScrollView { ... }` no longer throw `unknownView`, registering it in `ViewRegistry` and snapshotting vertical + horizontal cases.
- [x] Introduce shape builders for `Rectangle`, `RoundedRectangle`, and `Circle` (with support for decoding corner radii/line widths) so basic SwiftUI primitives no longer fail with `unknownView`, and register them in `ViewRegistry` alongside coverage in the snapshot suites.
- [x] Teach `ModifierRegistry` about basic styling modifiers like `cornerRadius`, `opacity`, and `shadow` by introducing dedicated builders in `Sources/EvalSwiftUI/Builder/ModifierBuilders` to reduce `unsupportedModifier` failures for common SwiftUI chains.
- [ ] Extend `ExpressionResolver.resolveExpression` to handle subscript expressions (`users[index]`, `dict["key"]`) so dynamic lookups feed into stacks/conditionals instead of bubbling `unsupportedExpression`, and add success/error diagnostics around array/dictionary subscripts with optional chaining.

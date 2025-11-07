import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct EvalSwiftUIMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SnapshotExpectationMacro.self
    ]
}

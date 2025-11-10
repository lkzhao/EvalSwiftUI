import SwiftUI

@freestanding(expression)
macro expectSnapshot(
    _ view: Any
) -> Void = #externalMacro(module: "Macros", type: "SnapshotExpectationMacro")

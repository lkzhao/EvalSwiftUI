import SwiftUI

struct TextViewBuilder: SwiftUIViewBuilder {
    let name = "Text"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let first = arguments.first,
              case let .string(value) = first.value.payload else {
            throw SwiftUIEvaluatorError.invalidArguments("Text expects a leading string literal.")
        }
        return AnyView(Text(value))
    }
}

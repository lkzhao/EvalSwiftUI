import SwiftUI

struct HStackViewBuilder: SwiftUIViewBuilder {
    let name = "HStack"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let contentArg = arguments.first(where: { argument in
            if case .viewContent = argument.value { return true }
            return false
        }), case let .viewContent(content) = contentArg.value else {
            throw SwiftUIEvaluatorError.invalidArguments("HStack requires a content closure.")
        }

        let views = try content.renderViews()
        return AnyView(HStack {
            ForEach(Array(views.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }
}

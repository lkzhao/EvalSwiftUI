import SwiftUI

struct VStackViewBuilder: SwiftUIViewBuilder {
    let name = "VStack"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let contentArg = arguments.first(where: { argument in
            if case .viewContent = argument.value { return true }
            return false
        }), case let .viewContent(content) = contentArg.value else {
            throw SwiftUIEvaluatorError.invalidArguments("VStack requires a content closure.")
        }

        let views = try content.renderViews()
        return AnyView(VStack {
            ForEach(Array(views.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }
}

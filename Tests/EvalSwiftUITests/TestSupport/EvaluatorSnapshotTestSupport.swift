import SwiftUI
@testable import EvalSwiftUI

struct Badge: View {
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag")
                .imageScale(.small)
            Text(label)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.2))
        .clipShape(Capsule())
    }
}

struct BadgeViewBuilder: SwiftUIViewBuilder {
    let name = "Badge"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let first = arguments.first, case let .string(label) = first.value.payload else {
            throw SwiftUIEvaluatorError.invalidArguments("Badge expects a leading string label.")
        }

        return AnyView(Badge(label: label))
    }
}

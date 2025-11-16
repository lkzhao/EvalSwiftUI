import SwiftUI

public struct GroupValueBuilder: RuntimeValueBuilder {
    public let name = "Group"
    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "content", type: "() -> Content", defaultValue: nil)
                ],
                build: { arguments, _ in
                    guard let function = arguments.value(named: "content")?.asFunction else {
                        throw RuntimeError.invalidArgument("Group requires a content closure.")
                    }
                    let views = try function.renderRuntimeViews().compactMap { $0.asSwiftUIView }
                    let groupView = AnyView(
                        Group {
                            ForEach(Array(views.enumerated()), id: \.0) { _, view in
                                view
                            }
                        }
                    )
                    return .swiftUI(.view(groupView))
                }
            )
        ]
    }
}

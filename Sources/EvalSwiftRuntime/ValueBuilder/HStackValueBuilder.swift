import SwiftUI

public struct HStackValueBuilder: RuntimeValueBuilder {
    public let name = "HStack"

    public let definitions: [RuntimeBuilderDefinition] = [
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(
                    name: "alignment",
                    type: "VerticalAlignment",
                    defaultValue: .swiftUI(.verticalAlignment(.center))
                ),
                RuntimeParameter(name: "spacing", type: "Double", defaultValue: .void),
                RuntimeParameter(name: "content", type: "() -> Content", defaultValue: nil)
            ],
            build: { arguments, _ in
                let alignment = arguments.value(named: "alignment")?.asVerticalAlignment ?? .center
                let spacing = arguments.value(named: "spacing")?.asCGFloat
                let contentFunction = arguments.value(named: "content")?.asFunction
                let contentViews = try contentFunction?.renderRuntimeViews().compactMap { $0.asSwiftUIView } ?? []

                let hStack = HStack(alignment: alignment, spacing: spacing) {
                    ForEach(0..<contentViews.count, id: \.self) { index in
                        contentViews[index]
                    }
                }
                return .swiftUI(.view(AnyView(hStack)))
            }
        )
    ]
}

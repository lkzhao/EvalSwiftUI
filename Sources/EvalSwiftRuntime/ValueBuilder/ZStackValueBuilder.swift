import SwiftUI

public struct ZStackValueBuilder: RuntimeValueBuilder {
    public let name = "ZStack"

    public let definitions: [RuntimeBuilderDefinition] = [
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(
                    name: "alignment",
                    type: "Alignment",
                    defaultValue: .swiftUI(.alignment(.center))
                ),
                RuntimeParameter(name: "content", type: "() -> Content", defaultValue: nil)
            ],
            build: { arguments, _ in
                let alignment = arguments.value(named: "alignment")?.asAlignment ?? .center
                let contentFunction = arguments.value(named: "content")?.asFunction
                let contentViews = try contentFunction?.renderRuntimeViews().compactMap { $0.asSwiftUIView } ?? []

                let zStack = ZStack(alignment: alignment) {
                    ForEach(0..<contentViews.count, id: \.self) { index in
                        contentViews[index]
                    }
                }

                return .swiftUI(.view(AnyView(zStack)))
            }
        )
    ]
}

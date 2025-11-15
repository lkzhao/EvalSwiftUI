//
//  VStackValueBuilder.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/14/25.
//

import SwiftUI

public struct VStackValueBuilder: RuntimeValueBuilder {
    public let name = "VStack"

    public let definitions: [RuntimeBuilderDefinition] = [
        RuntimeBuilderDefinition(
            parameters: [
                RuntimeParameter(name: "alignment", type: "Alignment", defaultValue: .swiftUI(.alignment(.center))),
                RuntimeParameter(name: "spacing", type: "Double", defaultValue: .void),
                RuntimeParameter(name: "content", type: "() -> Content", defaultValue: nil)
            ],
            build: { arguments, _ in
                let alignment = arguments.value(named: "alignment")?.asAlignment ?? .center
                let spacing = arguments.value(named: "spacing")?.asDouble.map { CGFloat($0) } ?? nil
                let contentFunction = arguments.value(named: "content")?.asFunction
                let contentViews = try contentFunction?.renderRuntimeViews().compactMap { $0.asSwiftUIView } ?? []

                let vStack = VStack(alignment: alignment.horizontal, spacing: spacing) {
                    ForEach(0..<contentViews.count, id: \.self) { index in
                        contentViews[index]
                    }
                }
                return .swiftUI(.view(AnyView(vStack)))
            }
        ),
    ]
}

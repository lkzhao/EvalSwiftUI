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
                let alignment = arguments.first(where: { $0.name == "alignment" })?.value.asAlignment ?? .center
                let spacing = arguments.first(where: { $0.name == "spacing" })?.value.asDouble.map { CGFloat($0) } ?? nil
                let contentViews = try arguments.first(where: { $0.name == "content" })?.value.asFunction?.renderRuntimeViews().compactMap { $0.asSwiftUIView } ?? []

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

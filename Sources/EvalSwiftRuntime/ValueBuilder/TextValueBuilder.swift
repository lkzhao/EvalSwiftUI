//
//  TextValueBuilder.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/14/25.
//

import SwiftUI

public struct TextValueBuilder: RuntimeValueBuilder {
    public let name = "Text"

    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        self.definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "content", type: "String")
                ],
                build: { arguments, _ in
                    guard let content = arguments.first?.value.asString else {
                        throw RuntimeError.invalidArgument("Text expects a string content.")
                    }
                    return .swiftUI(.view(Text(content)))
                }
            )
        ]
    }
}

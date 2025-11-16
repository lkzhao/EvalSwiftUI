import SwiftUI

public struct FontWeightValueBuilder: RuntimeValueBuilder {
    public let name = "Font.Weight"
    public let definitions: [RuntimeBuilderDefinition] = []

    public init() {}

    public func populate(type: RuntimeType) {
        let weights: [(String, Font.Weight)] = [
            ("ultraLight", .ultraLight),
            ("thin", .thin),
            ("light", .light),
            ("regular", .regular),
            ("medium", .medium),
            ("semibold", .semibold),
            ("bold", .bold),
            ("heavy", .heavy),
            ("black", .black)
        ]
        for (name, weight) in weights {
            type.define(name, value: .swiftUI(.fontWeight(weight)))
        }
    }
}

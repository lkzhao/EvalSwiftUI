import SwiftUI

enum SwiftUIRuntimeConstants {
    static func register(in module: RuntimeModule) {
        registerColors(in: module)
        registerFonts(in: module)
        registerAlignments(in: module)
        registerImageScales(in: module)
    }

    private static func registerColors(in scope: RuntimeModule) {
        let colors: [(String, Color)] = [
            ("clear", .clear),
            ("black", .black),
            ("blue", .blue),
            ("brown", .brown),
            ("cyan", .cyan),
            ("gray", .gray),
            ("green", .green),
            ("indigo", .indigo),
            ("mint", .mint),
            ("orange", .orange),
            ("pink", .pink),
            ("purple", .purple),
            ("red", .red),
            ("teal", .teal),
            ("white", .white),
            ("yellow", .yellow),
            ("primary", .primary),
            ("secondary", .secondary),
            ("accentColor", .accentColor)
        ]

        let colorInstance = RuntimeInstance(parent: scope)
        for (name, color) in colors {
            scope.define(name, value: .swiftUI(.color(color)))
            colorInstance.define(name, value: .swiftUI(.color(color)))
        }
        scope.define("Color", value: .instance(colorInstance))
    }

    private static func registerFonts(in scope: RuntimeModule) {
        let fonts: [(String, Font)] = [
            ("largeTitle", .largeTitle),
            ("title", .title),
            ("title2", .title2),
            ("title3", .title3),
            ("headline", .headline),
            ("subheadline", .subheadline),
            ("body", .body),
            ("callout", .callout),
            ("caption", .caption),
            ("caption2", .caption2),
            ("footnote", .footnote)
        ]

        let fontInstance = RuntimeInstance(parent: scope)
        for (name, font) in fonts {
            scope.define(name, value: .swiftUI(.font(font)))
            fontInstance.define(name, value: .swiftUI(.font(font)))
        }
        scope.define("Font", value: .instance(fontInstance))
    }

    private static func registerAlignments(in scope: RuntimeModule) {
        let alignments: [(String, Alignment)] = [
            ("center", .center),
            ("leading", .leading),
            ("trailing", .trailing),
            ("top", .top),
            ("bottom", .bottom),
            ("topLeading", .topLeading),
            ("topTrailing", .topTrailing),
            ("bottomLeading", .bottomLeading),
            ("bottomTrailing", .bottomTrailing)
        ]

        let alignmentInstance = RuntimeInstance(parent: scope)
        for (name, alignment) in alignments {
            scope.define(name, value: .swiftUI(.alignment(alignment)))
            alignmentInstance.define(name, value: .swiftUI(.alignment(alignment)))
        }
        scope.define("Alignment", value: .instance(alignmentInstance))
    }

    private static func registerImageScales(in scope: RuntimeModule) {
        let scales: [(String, Image.Scale)] = [
            ("small", .small),
            ("medium", .medium),
            ("large", .large)
        ]

        let imageInstance = RuntimeInstance(parent: scope)
        let scaleInstance = RuntimeInstance(parent: imageInstance)
        imageInstance.define("Scale", value: .instance(scaleInstance))
        scope.define("Image", value: .instance(imageInstance))
        for (name, scale) in scales {
            scope.define(name, value: .swiftUI(.imageScale(scale)))
            scaleInstance.define(name, value: .swiftUI(.imageScale(scale)))
        }
    }
}

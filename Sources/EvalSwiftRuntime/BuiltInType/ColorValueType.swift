

public struct ColorValueType: RuntimeBuiltInType {
    public let name = "Color"
    public func makeValue(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue {
        throw RuntimeError.unsupportedExpression("Color initializer unsupported")
    }
    public func populate(type: RuntimeType) {
        type.define("clear", value: .swiftUI(.color(.clear)))
        type.define("black", value: .swiftUI(.color(.black)))
        type.define("blue", value: .swiftUI(.color(.blue)))
        type.define("brown", value: .swiftUI(.color(.brown)))
        type.define("cyan", value: .swiftUI(.color(.cyan)))
        type.define("gray", value: .swiftUI(.color(.gray)))
        type.define("green", value: .swiftUI(.color(.green)))
        type.define("indigo", value: .swiftUI(.color(.indigo)))
        type.define("mint", value: .swiftUI(.color(.mint)))
        type.define("orange", value: .swiftUI(.color(.orange)))
        type.define("pink", value: .swiftUI(.color(.pink)))
        type.define("purple", value: .swiftUI(.color(.purple)))
        type.define("red", value: .swiftUI(.color(.red)))
        type.define("teal", value: .swiftUI(.color(.teal)))
        type.define("white", value: .swiftUI(.color(.white)))
        type.define("yellow", value: .swiftUI(.color(.yellow)))
        type.define("primary", value: .swiftUI(.color(.primary)))
        type.define("secondary", value: .swiftUI(.color(.secondary)))
        type.define("accentColor", value: .swiftUI(.color(.accentColor)))
    }
}


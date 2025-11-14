

public struct ImageValueType: RuntimeBuiltInType {
    public let name = "Image"
    public func makeValue(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue {
        .instance(RuntimeInstance(builder: ImageRuntimeViewBuilder(), arguments: arguments, parent: scope))
    }
    public func populate(type: RuntimeType) {
        type.define("Scale", value: .type(RuntimeType(builtInType: ImageScaleValueType(), parent: type)))
    }
}

public struct ImageScaleValueType: RuntimeBuiltInType {
    public let name = "Scale"
    public func makeValue(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue {
        throw RuntimeError.unsupportedExpression("Image.Scale initializer unsupported")
    }
    public func populate(type: RuntimeType) {
        type.define("small", value: .swiftUI(.imageScale(.small)))
        type.define("medium", value: .swiftUI(.imageScale(.medium)))
        type.define("large", value: .swiftUI(.imageScale(.large)))
    }
}

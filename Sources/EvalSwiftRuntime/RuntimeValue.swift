import Foundation
import SwiftUI
import EvalSwiftIR

public enum RuntimeValue {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case keyPath(RuntimeKeyPath)
    case type(RuntimeType)
    case function(RuntimeFunction)
    case instance(RuntimeInstance)
    case array([RuntimeValue])
    case void
    case swiftUI(SwiftUIRuntimeValue)
}

extension RuntimeValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int(let value):
            return String(value)
        case .double(let number):
            return String(number)
        case .string(let string):
            return string
        case .bool(let bool):
            return String(bool)
        case .keyPath:
            return "<KeyPath>"
        case .type(let type):
            return "<Type \(type.name)>"
        case .instance(let instance):
            return String(describing: instance)
        case .array(let values):
            return values.map { "\($0)" }.joined(separator: ",")
        case .function:
            return "<Function>"
        case .void:
            return "void"
        case .swiftUI(let value):
            return value.description
        }
    }
}

extension RuntimeValue {
    var asString: String? {
        switch self {
        case .string(let string):
            return string
        case .int(let value):
            return String(value)
        case .double(let number):
            return String(number)
        case .bool(let bool):
            return String(bool)
        default:
            return nil
        }
    }

    var asDouble: Double? {
        switch self {
        case .int(let value):
            return Double(value)
        case .double(let number):
            return number
        case .string(let string):
            return Double(string)
        default:
            return nil
        }
    }

    var asInt: Int? {
        switch self {
        case .int(let value):
            return value
        case .double(let number):
            return Int(number)
        case .string(let string):
            return Int(string)
        case .bool(let bool):
            return bool ? 1 : 0
        default:
            return nil
        }
    }

    var asBool: Bool? {
        switch self {
        case .bool(let bool):
            return bool
        case .int(let value):
            return value != 0
        case .double(let number):
            return number != 0
        case .string(let string):
            return Bool(string)
        default:
            return nil
        }
    }

    var asColor: Color? {
        guard case .swiftUI(let value) = self, case .color(let color) = value else { return nil }
        return color
    }

    var asFont: Font? {
        guard case .swiftUI(let value) = self, case .font(let font) = value else { return nil }
        return font
    }

    var asAlignment: Alignment? {
        guard case .swiftUI(let value) = self, case .alignment(let alignment) = value else { return nil }
        return alignment
    }

    var asImageScale: Image.Scale? {
        guard case .swiftUI(let value) = self, case .imageScale(let scale) = value else { return nil }
        return scale
    }

    var asAxisSet: Axis.Set? {
        guard case .swiftUI(let value) = self, case .axisSet(let axis) = value else { return nil }
        return axis
    }

    var asRoundedCornerStyle: RoundedCornerStyle? {
        guard case .swiftUI(let value) = self, case .roundedCornerStyle(let style) = value else { return nil }
        return style
    }

    var asInstance: RuntimeInstance? {
        guard case .instance(let instance) = self else { return nil }
        return instance
    }

    @MainActor
    var asSwiftUIView: AnyView? {
        if let color = asColor {
            return AnyView(color)
        }
        if case .swiftUI(let value) = self, case .view(let view) = value {
            return AnyView(view)
        }
        if case .instance(let instance) = self {
            return try? instance.makeSwiftUIView()
        }
        return nil
    }
}

extension RuntimeValue {
    public enum RuntimeValueType: CustomStringConvertible, Hashable {
        case int
        case double
        case string
        case bool
        case keyPath
        case type
        case instance
        case array
        case function([RuntimeParameter])
        case void
        case swiftUI

        public var description: String {
            switch self {
            case .int:
                "Int"
            case .double:
                "Double"
            case .string:
                "String"
            case .bool:
                "Bool"
            case .keyPath:
                "KeyPath"
            case .type:
                "Type"
            case .instance:
                "Instance"
            case .array:
                "Array"
            case .function(let params):
                "Function(\(params.map { "\($0.label ?? "_"): \($0.type ?? "Any")" }.joined(separator: ", ")))"
            case .void:
                "Void"
            case .swiftUI:
                "SwiftUI"
            }
        }
    }

    public var valueType: RuntimeValueType {
        switch self {
        case .int:
            return .int
        case .double:
            return .double
        case .string:
            return .string
        case .bool:
            return .bool
        case .keyPath:
            return .keyPath
        case .type:
            return .type
        case .instance:
            return .instance
        case .array:
            return .array
        case .function(let function):
            return .function(function.parameters)
        case .void:
            return .void
        case .swiftUI:
            return .swiftUI
        }
    }
}

public enum SwiftUIRuntimeValue {
    case view(any View)
    case color(Color)
    case font(Font)
    case alignment(Alignment)
    case imageScale(Image.Scale)
    case axisSet(Axis.Set)
    case roundedCornerStyle(RoundedCornerStyle)
}

extension SwiftUIRuntimeValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .view:
            return "<View>"
        case .color:
            return "<Color>"
        case .font:
            return "<Font>"
        case .alignment:
            return "<Alignment>"
        case .imageScale:
            return "<Image.Scale>"
        case .axisSet:
            return "<Axis.Set>"
        case .roundedCornerStyle:
            return "<RoundedCornerStyle>"
        }
    }
}

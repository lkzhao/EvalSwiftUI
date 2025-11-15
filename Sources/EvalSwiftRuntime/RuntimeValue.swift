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
    case dictionary([AnyHashable: RuntimeValue])
    case uuid(UUID)
    case date(Date)
    case binding(RuntimeBinding)
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
        case .dictionary:
            return "<Dictionary>"
        case .uuid(let uuid):
            return uuid.uuidString
        case .date(let date):
            return date.description
        case .function:
            return "<Function>"
        case .binding:
            return "<Binding>"
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
        case .uuid(let uuid):
            return uuid.uuidString
        default:
            return nil
        }
    }

    var asKeyPath: RuntimeKeyPath? {
        guard case .keyPath(let keyPath) = self else { return nil }
        return keyPath
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

    var asCGFloat: CGFloat? {
        guard let doubleValue = asDouble else {
            return nil
        }
        return CGFloat(doubleValue)
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

    var asArray: [RuntimeValue]? {
        switch self {
        case .array(let values):
            return values
        default:
            return nil
        }
    }

    var asDictionary: [AnyHashable: RuntimeValue]? {
        switch self {
        case .dictionary(let values):
            return values
        default:
            return nil
        }
    }

    var asUUID: UUID? {
        if case .uuid(let value) = self {
            return value
        }
        return nil
    }

    var asDate: Date? {
        if case .date(let value) = self {
            return value
        }
        return nil
    }

    var asFunction: RuntimeFunction? {
        guard case .function(let function) = self else { return nil }
        return function
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

    var asHorizontalAlignment: HorizontalAlignment? {
        guard case .swiftUI(let value) = self, case .horizontalAlignment(let alignment) = value else {
            return nil
        }
        return alignment
    }

    var asVerticalAlignment: VerticalAlignment? {
        guard case .swiftUI(let value) = self, case .verticalAlignment(let alignment) = value else {
            return nil
        }
        return alignment
    }

    var asImageScale: Image.Scale? {
        guard case .swiftUI(let value) = self, case .imageScale(let scale) = value else { return nil }
        return scale
    }

    var asFillStyle: FillStyle? {
        guard case .swiftUI(let value) = self, case .fillStyle(let style) = value else { return nil }
        return style
    }

    var asBlendMode: BlendMode? {
        guard case .swiftUI(let value) = self, case .blendMode(let mode) = value else { return nil }
        return mode
    }

    var asAxisSet: Axis.Set? {
        guard case .swiftUI(let value) = self, case .axisSet(let axis) = value else { return nil }
        return axis
    }

    var asRoundedCornerStyle: RoundedCornerStyle? {
        guard case .swiftUI(let value) = self, case .roundedCornerStyle(let style) = value else { return nil }
        return style
    }

    var asShapeStyle: AnyShapeStyle? {
        switch self {
        case .swiftUI(let value):
            switch value {
            case .shapeStyle(let style):
                return style
            case .color(let color):
                return AnyShapeStyle(color)
            default:
                return nil
            }
        default:
            return nil
        }
    }

    var asShape: AnyShape? {
        guard case .swiftUI(let value) = self, case .shape(let shape) = value else {
            return nil
        }
        return shape
    }

    var asInstance: RuntimeInstance? {
        guard case .instance(let instance) = self else { return nil }
        return instance
    }

    var asBinding: RuntimeBinding? {
        guard case .binding(let binding) = self else { return nil }
        return binding
    }

    var asSwiftUIView: AnyView? {
        if let color = asColor {
            return AnyView(color)
        }
        if case .swiftUI(let value) = self, case .view(let view) = value {
            return AnyView(view)
        }
        if case .swiftUI(let value) = self, case .shape(let shape) = value {
            return AnyView(shape)
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
        case dictionary
        case uuid
        case date
        case function([RuntimeParameter])
        case binding
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
            case .dictionary:
                "Dictionary"
            case .uuid:
                "UUID"
            case .date:
                "Date"
            case .function(let params):
                "(\(params.map { "\($0.label ?? "_"): \($0.type ?? "Any")" }.joined(separator: ", "))) -> Unknown"
            case .binding:
                "Binding"
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
        case .dictionary:
            return .dictionary
        case .uuid:
            return .uuid
        case .date:
            return .date
        case .function(let function):
            return .function(function.parameters)
        case .binding:
            return .binding
        case .void:
            return .void
        case .swiftUI:
            return .swiftUI
        }
    }
}

extension RuntimeValue {
    var asAnyHashable: AnyHashable? {
        switch self {
        case .int(let value):
            return AnyHashable(value)
        case .double(let number):
            return AnyHashable(number)
        case .string(let string):
            return AnyHashable(string)
        case .bool(let bool):
            return AnyHashable(bool)
        case .uuid(let uuid):
            return AnyHashable(uuid)
        case .date(let date):
            return AnyHashable(date)
        default:
            return nil
        }
    }
}

public enum SwiftUIRuntimeValue {
    case view(any View)
    case color(Color)
    case font(Font)
    case alignment(Alignment)
    case horizontalAlignment(HorizontalAlignment)
    case verticalAlignment(VerticalAlignment)
    case imageScale(Image.Scale)
    case fillStyle(FillStyle)
    case blendMode(BlendMode)
    case axisSet(Axis.Set)
    case roundedCornerStyle(RoundedCornerStyle)
    case shapeStyle(AnyShapeStyle)
    case shape(AnyShape)
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
        case .horizontalAlignment:
            return "<HorizontalAlignment>"
        case .verticalAlignment:
            return "<VerticalAlignment>"
        case .imageScale:
            return "<Image.Scale>"
        case .fillStyle:
            return "<FillStyle>"
        case .blendMode:
            return "<BlendMode>"
        case .axisSet:
            return "<Axis.Set>"
        case .roundedCornerStyle:
            return "<RoundedCornerStyle>"
        case .shapeStyle:
            return "<ShapeStyle>"
        case .shape:
            return "<Shape>"
        }
    }
}

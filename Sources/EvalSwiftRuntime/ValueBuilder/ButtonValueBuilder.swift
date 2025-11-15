import SwiftUI

public struct ButtonValueBuilder: RuntimeValueBuilder {
    public let name = "Button"

    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        self.definitions = [
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(label: "_", name: "title", type: "String"),
                    RuntimeParameter(name: "action", type: "() -> Void")
                ],
                build: { arguments, _ in
                    guard let title = arguments.value(named: "title")?.asString else {
                        throw RuntimeError.invalidArgument("Button(title:) expects a string title.")
                    }
                    let action = try Self.makeActionHandler(
                        from: arguments.value(named: "action")?.asFunction
                    )

                    let button = Button(title, action: action)
                    return .swiftUI(.view(AnyView(button)))
                }
            ),
            RuntimeBuilderDefinition(
                parameters: [
                    RuntimeParameter(name: "action", type: "() -> Void"),
                    RuntimeParameter(name: "label", type: "() -> Content")
                ],
                build: { arguments, _ in
                    let action = try Self.makeActionHandler(
                        from: arguments.value(named: "action")?.asFunction
                    )
                    let labelView = try Self.makeLabelView(
                        from: arguments.value(named: "label")?.asFunction
                    )

                    let button = Button(action: action) {
                        labelView
                    }
                    return .swiftUI(.view(AnyView(button)))
                }
            )
        ]
    }

    private static func makeActionHandler(
        from function: RuntimeFunction?
    ) throws -> () -> Void {
        guard let function else {
            throw RuntimeError.invalidArgument("Button requires an action closure.")
        }
        return {
            do {
                _ = try function.invoke()
            } catch {
                assertionFailure("Button action failed with error: \(error)")
            }
        }
    }

    private static func makeLabelView(
        from function: RuntimeFunction?
    ) throws -> AnyView {
        guard let function else {
            throw RuntimeError.invalidArgument("Button requires a label closure.")
        }
        let renderedValues = try function.renderRuntimeViews()
        if let firstView = renderedValues.compactMap({ $0.asSwiftUIView }).first {
            return firstView
        }
        return AnyView(EmptyView())
    }
}

private extension Array where Element == RuntimeArgument {
    func value(named name: String) -> RuntimeValue? {
        first(where: { $0.name == name })?.value
    }
}

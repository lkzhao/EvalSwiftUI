import SwiftSyntax

extension AttributeListSyntax {
    var containsStateAttribute: Bool {
        contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else {
                return false
            }
            return attribute.attributeName.trimmedDescription == "State"
        }
    }
}

import Foundation

struct KeyboardTypeValueBuilder: RuntimeValueBuilder {
    let name = "UIKeyboardType"
    let definitions: [RuntimeBuilderDefinition] = []

    func populate(type: RuntimeType) {
        let values = [
            "default",
            "asciiCapable",
            "numbersAndPunctuation",
            "url",
            "numberPad",
            "phonePad",
            "namePhonePad",
            "emailAddress",
            "decimalPad",
            "twitter",
            "webSearch"
        ]
        for value in values {
            type.define(value, value: .string(value))
        }
    }
}

struct TextContentTypeValueBuilder: RuntimeValueBuilder {
    let name = "UITextContentType"
    let definitions: [RuntimeBuilderDefinition] = []

    func populate(type: RuntimeType) {
        let values = [
            "username",
            "password",
            "emailAddress",
            "oneTimeCode"
        ]
        for value in values {
            type.define(value, value: .string(value))
        }
    }
}

struct TextInputAutocapitalizationValueBuilder: RuntimeValueBuilder {
    let name = "TextInputAutocapitalization"
    let definitions: [RuntimeBuilderDefinition] = []

    func populate(type: RuntimeType) {
        let values = ["never", "sentences", "words", "characters"]
        for value in values {
            type.define(value, value: .string(value))
        }
    }
}

struct SubmitLabelValueBuilder: RuntimeValueBuilder {
    let name = "SubmitLabel"
    let definitions: [RuntimeBuilderDefinition] = []

    func populate(type: RuntimeType) {
        let values = ["next", "return", "go", "search", "send", "done", "continue"]
        for value in values {
            type.define(value, value: .string(value))
        }
    }
}

# TODO

- [x] Implement baseline keypath support (member access, optional chaining, force unwraps)
- [x] Parse key paths that specify explicit roots or subscript components (e.g. `\Todo.id`, `\.items[0].label`)
    - [x] Extend `KeyPathIR` to capture type roots and subscript arguments
    - [x] Teach the parser to surface those components (detect literal indices, labels)
    - [x] Add runtime evaluation for array subscripts, dictionary lookups, and root lookups
    - [x] Snapshot tests covering `\.items[0].id`, `\TodoItem.id`, and optional chaining combos
- [x] Allow `ForEach(id:)` to accept Hashable values beyond primitives (UUID/custom structs)
    - [x] Surface `UUID`, `Date`, and other Foundation literals as Hashable runtime values
    - [x] Detect `Identifiable.id` stored on `RuntimeInstance` and forward to `AnyHashable`
- [x] Implement additional shape builders (Circle, Capsule, Rectangle, etc.) that emit `.shape(AnyShape)`
- [x] Add modifier builders for `border`, `clipShape`, `mask`, and `blendMode`
- [ ] Support gradient ShapeStyles (LinearGradient, AngularGradient, RadialGradient builders plus Gradient parsing)
- [ ] Extend literal parsing for assets/hex so `Color(uiColor:)`-style expressions work inside evaluated snippets
- [ ] Introduce stateful modifiers like `animation`, `transition`, and `onTapGesture`
- [ ] Parse and evaluate simple `enum` declarations so `Field`-style focus enums compile inside evaluated views.
- [ ] Add builders for `Spacer`, `Group`, `TextField`, and `SecureField`, including `Spacer(minLength:)` and binding-backed text inputs.
- [ ] Implement text-input modifiers (`keyboardType`, `textContentType`, `textInputAutocapitalization`, `autocorrectionDisabled`, `submitLabel`, `.focused(_:equals:)`, `.onSubmit`) with a `FocusState`-aware runtime binding.
- [ ] Allow `Circle`, `RoundedRectangle`, etc. to respond to `.fill`, `.stroke`, `.strokeBorder`, and `.contentShape`, plus support the `LinearGradient(colors:startPoint:endPoint:)` initializer.
- [ ] Provide view modifiers for `.buttonStyle`, `.tint`, `.disabled`, `.animation(_:value:)`, `.accessibilityLabel`, `.accessibilityHidden`, and propagate `contentShape` to hit-testing.
- [ ] Expand Font/Color helpers with `Font.system(size:weight:)`, `Font.Weight` cases, `.bold()`, `Color(.systemGroupedBackground)`, semantic colors (`.secondary`, `.quaternary`, etc.), and honor `.frame(maxWidth: .infinity)`.
- [ ] Teach the `padding` modifier to accept `Edge.Set` + length, and add an `Edge.Set` value builder for cases like `.padding(.top, 8)`.
- [ ] Enhance the expression interpreter to understand ternary `?:`, unary `!`, `Bool.toggle()`, and basic `String`/`Substring` helpers (`split`, `count`, `contains`, `hasPrefix`, `hasSuffix`) used by the form validation logic.
- [ ] End-to-end goal: `LoginPrototypeView` compiles and renders identically in EvalSwiftUI, covering focus state, text-field behaviors, button styles, semantic colors, gradients, and validation logic:

```
import SwiftUI

struct LoginPrototypeView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    enum Field { case email, password }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
                Text("Sign in")
                    .font(.title2).bold()
                Text("Access your AI assistant")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))

                HStack {
                    Image(systemName: "lock")
                        .foregroundStyle(.secondary)
                    Group {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                    }
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))

                HStack {
                    Button("Forgot password?") {}
                        .font(.footnote)
                    Spacer()
                    Button("Create account") {}
                        .font(.footnote).bold()
                }
                .tint(.indigo)
            }

            Button {
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
            .animation(.default, value: isValid)

            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                Text("or")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            }

            VStack(spacing: 8) {
                Button {
                } label: {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Sign in with Apple").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Sign in with Google").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Text("By continuing, you agree to the Terms and Privacy Policy.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(Color(.systemGroupedBackground))
    }

    private var isValid: Bool {
        isValidEmail(email) && password.count >= 8
    }

    private func isValidEmail(_ s: String) -> Bool {
        let comps = s.split(separator: "@")
        guard comps.count == 2, !comps[0].isEmpty else { return false }
        let domain = comps[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }
}
```

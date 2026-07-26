import SwiftUI

enum ButtonVariant {
    case primary, secondary, danger
}

struct PrimaryButton: View {
    let label: String
    var variant: ButtonVariant = .primary
    var disabled: Bool = false
    var loading: Bool = false
    let action: () -> Void

    private var foreground: Color {
        variant == .secondary ? Theme.routeBlue : .white
    }

    var body: some View {
        Button(action: action) {
            Group {
                if loading {
                    ProgressView().tint(foreground)
                } else {
                    Text(label)
                        .font(.display(16, .semibold))
                        .foregroundColor(foreground)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius)
                    .stroke(variant == .secondary ? Theme.routeBlue.opacity(0.5) : .clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
            .shadow(
                color: variant == .primary ? Theme.routeBlue.opacity(0.35) : .clear,
                radius: 14, x: 0, y: 8
            )
        }
        .buttonStyle(PressableStyle())
        .opacity(disabled ? 0.5 : 1)
        .disabled(disabled || loading)
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary: Theme.buttonGradient
        case .danger: LinearGradient(colors: [Theme.danger, Theme.danger.opacity(0.85)], startPoint: .top, endPoint: .bottom)
        case .secondary: Theme.surface
        }
    }
}

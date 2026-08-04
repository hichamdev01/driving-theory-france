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
            ZStack {
                // Background
                backgroundFill

                // Glass shine overlay for primary/danger
                if variant != .secondary {
                    LinearGradient(
                        colors: [.white.opacity(0.14), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }

                // Label / spinner
                Group {
                    if loading {
                        ProgressView().tint(foreground)
                    } else {
                        Text(label)
                            .font(.display(18, .semibold))
                            .foregroundColor(foreground)
                            .tracking(0.2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius)
                    .stroke(
                        variant == .secondary ? Theme.routeBlue.opacity(0.4) : .clear,
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
            .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PressableStyle())
        .opacity(disabled ? 0.45 : 1)
        .disabled(disabled || loading)
    }

    @ViewBuilder
    private var backgroundFill: some View {
        switch variant {
        case .primary: Theme.buttonGradient
        case .danger:  Theme.dangerGradient
        case .secondary: Theme.surface
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary: Color(hex: "0F44C4").opacity(0.28)
        case .danger:  Color(hex: "B51D30").opacity(0.28)
        case .secondary: .clear
        }
    }
}

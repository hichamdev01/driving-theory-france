import SwiftUI

enum ButtonVariant {
    case primary, secondary, danger
}

struct PrimaryButton: View {
    let label: String
    var variant: ButtonVariant = .primary
    var disabled: Bool = false
    var loading: Bool = false
    var icon: String? = nil
    let action: () -> Void

    private var foreground: Color {
        switch variant {
        case .primary, .danger: .white
        case .secondary: AppColor.action
        }
    }

    private var background: AnyShapeStyle {
        switch variant {
        case .primary: AnyShapeStyle(Theme.buttonGradient)
        case .secondary: AnyShapeStyle(Theme.surface)
        case .danger: AnyShapeStyle(Theme.dangerGradient)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                if loading {
                    ProgressView()
                        .tint(foreground)
                        .accessibilityHidden(true)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                        .accessibilityHidden(true)
                }

                Text(label)
                    .font(.headline)
                    .foregroundStyle(foreground)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, AppSpacing.standard)
            .background(background, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
            .adaptiveStroke(
                variant == .secondary ? Theme.border : Color.white.opacity(0.12),
                radius: AppRadius.control
            )
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .disabled(disabled || loading)
        .opacity(disabled ? 0.50 : 1)
        .shadow(
            color: variant == .secondary || disabled ? .clear : AppColor.action.opacity(0.22),
            radius: 12,
            y: 6
        )
    }
}

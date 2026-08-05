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
        switch variant {
        case .primary, .danger: .white
        case .secondary: AppColor.action
        }
    }

    private var background: Color {
        switch variant {
        case .primary: AppColor.action
        case .secondary: AppColor.fillSubtle
        case .danger: AppColor.danger
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                if loading {
                    ProgressView()
                        .tint(foreground)
                        .accessibilityHidden(true)
                }

                Text(label)
                    .font(.headline)
                    .foregroundStyle(foreground)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, AppSpacing.standard)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .disabled(disabled || loading)
        .opacity(disabled ? 0.48 : 1)
    }
}

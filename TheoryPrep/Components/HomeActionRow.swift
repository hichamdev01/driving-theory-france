import SwiftUI

/// A consistent, full-width destination row for the home training menu.
struct HomeActionRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: AppSpacing.medium) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(AppColor.action)
                        .frame(width: 32)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppColor.text)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
    }
}

import SwiftUI

struct CardView<Content: View>: View {
    var action: (() -> Void)?
    var background: Color = AppColor.surface
    var borderColor: Color? = AppColor.separator
    @ViewBuilder let content: () -> Content

    var body: some View {
        if let action {
            Button(action: action) { cardBody }
                .buttonStyle(PressableStyle())
        } else {
            cardBody
        }
    }

    private var cardBody: some View {
        content()
            .padding(AppSpacing.standard)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(borderColor ?? .clear, lineWidth: borderColor == nil ? 0 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

import SwiftUI

struct CardView<Content: View>: View {
    var action: (() -> Void)?
    var background: Color = Theme.surface
    var borderColor: Color? = Theme.border
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
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(borderColor ?? .clear, lineWidth: borderColor == nil ? 0 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .shadow(color: Theme.text.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

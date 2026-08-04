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
                    .stroke(borderColor ?? .clear, lineWidth: borderColor == nil ? 0 : 0.75)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            // Two-layer shadow: tight dark for definition, wide soft for elevation
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 5)
    }
}

import SwiftUI

struct RoadSignDetailView: View {
    let signId: Int64
    @EnvironmentObject var settings: AppSettings
    @State private var sign: RoadSignWithTranslation?

    var body: some View {
        ScrollView {
            if let sign {
                VStack(spacing: 16) {
                    RoadSignImageView(imagePath: sign.imagePath, shape: sign.shape, color: sign.color, size: 160)
                        .padding(.vertical, 24)

                    Text(sign.name)
                        .font(.display(24, .bold))
                        .foregroundColor(Theme.text)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text(sign.categoryName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.routeBlue)
                        .textCase(.uppercase)

                    CardView {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(settings.t(.meaning))
                                .font(.caption.weight(.bold))
                                .foregroundColor(Theme.textMuted)
                                .textCase(.uppercase)
                            Text(sign.meaning)
                                .font(.body.weight(.semibold))
                                .foregroundColor(Theme.text)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(AppScreenBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard let language = settings.languageCode else { return }
            sign = Queries.getRoadSignById(Database.shared, signId, language)
        }
    }
}

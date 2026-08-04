import SwiftUI

struct RoadSignsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var signs: [RoadSignWithTranslation] = []

    private var grouped: [(String, [RoadSignWithTranslation])] {
        var order: [String] = []
        var map: [String: [RoadSignWithTranslation]] = [:]
        for sign in signs {
            if map[sign.categoryName] == nil {
                order.append(sign.categoryName)
                map[sign.categoryName] = []
            }
            map[sign.categoryName]!.append(sign)
        }
        return order.map { ($0, map[$0]!) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.t(.appName).uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Theme.routeBlue)
                        Text(settings.t(.roadSigns))
                            .font(.display(34, .bold))
                            .foregroundColor(Theme.text)
                    }
                    .padding(.top, 12)

                    ForEach(grouped, id: \.0) { categoryName, categorySigns in
                        Text(categoryName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                            .textCase(.uppercase)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                            ForEach(Array(categorySigns.enumerated()), id: \.element.id) { i, sign in
                                NavigationLink(destination: RoadSignDetailView(signId: sign.id)) {
                                    VStack(spacing: 8) {
                                        RoadSignImageView(imagePath: sign.imagePath, shape: sign.shape, color: sign.color, size: 48)
                                        Text(sign.name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.text)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                                }
                                .buttonStyle(PressableStyle())
                                .appear(i)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(
                    .bottom,
                    TabBarLayout.scrollContentBottomPadding - 20
                )
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear(perform: reload)
        }
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        signs = Queries.getRoadSigns(Database.shared, country, language)
    }
}

import SwiftUI

struct RoadSignsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var categories: [RoadSignCategorySummary] = []

    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        Text(settings.t(.signCountFormat, categories.reduce(0) { $0 + $1.signCount }))
                        Circle()
                            .fill(Theme.textMuted.opacity(0.45))
                            .frame(width: 3, height: 3)
                        Text(settings.t(.categoryCountFormat, categories.count))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.textMuted)

                    LazyVStack(spacing: 12) {
                        ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                            NavigationLink {
                                RoadSignCategoryView(category: category)
                            } label: {
                                RoadSignCategoryCard(category: category)
                            }
                            .buttonStyle(PressableStyle())
                            .appear(index)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, AppSpacing.section)
            }
            .background(AppScreenBackground())
            .navigationTitle(settings.t(.roadSigns))
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: reload)
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        categories = Queries.getRoadSignCategories(Database.shared, country, language)
    }
}

private struct RoadSignCategoryCard: View {
    let category: RoadSignCategorySummary

    private var presentation: (icon: String, color: Color, background: Color) {
        switch category.slug {
        case "danger":
            return ("exclamationmark.triangle.fill", Theme.danger, Theme.danger.opacity(0.10))
        case "obligation":
            return ("arrow.up.circle.fill", Theme.routeBlue, Theme.routeBlue.opacity(0.10))
        case "prohibition":
            return ("nosign", Theme.danger, Theme.danger.opacity(0.10))
        case "end_prohibition":
            return ("circle.slash", Theme.textMuted, Theme.surfaceAlt)
        default:
            return ("info.circle.fill", Theme.routeBlue, Theme.routeBlue.opacity(0.10))
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(presentation.background)
                Image(systemName: presentation.icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(presentation.color)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(category.name)
                    .font(.display(21, .bold))
                    .foregroundColor(Theme.text)
                    .multilineTextAlignment(.leading)
                Text("\(category.signCount)")
                    .font(.gauge(14, .bold))
                    .foregroundColor(Theme.textMuted)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textMuted)
                .padding(12)
                .background(Theme.surfaceAlt)
                .clipShape(Circle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 104)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct RoadSignCategoryView: View {
    let category: RoadSignCategorySummary
    @EnvironmentObject var settings: AppSettings
    @State private var signs: [RoadSignWithTranslation] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.display(30, .bold))
                        .foregroundColor(Theme.text)
                    Text(settings.t(.signCountFormat, category.signCount))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textMuted)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                    ForEach(Array(signs.enumerated()), id: \.element.id) { index, sign in
                        NavigationLink(destination: RoadSignDetailView(signId: sign.id)) {
                            VStack(spacing: 10) {
                                RoadSignImageView(
                                    imagePath: sign.imagePath,
                                    shape: sign.shape,
                                    color: sign.color,
                                    size: 68
                                )
                                Text(sign.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Theme.text)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, minHeight: 132)
                            .background(Theme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.controlRadius)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
                        }
                        .buttonStyle(PressableStyle())
                        .appear(index)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppScreenBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        signs = Queries.getRoadSigns(Database.shared, country, language, categoryId: category.id)
    }
}

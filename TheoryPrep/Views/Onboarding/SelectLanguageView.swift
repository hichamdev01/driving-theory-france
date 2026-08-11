import SwiftUI

struct SelectLanguageView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var languages: [Language] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                introCard

                HStack(alignment: .top, spacing: AppSpacing.standard) {
                    LearningRouteMark()

                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text(settings.t(.selectLanguageTitle))
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppColor.text)
                            .accessibilityAddTraits(.isHeader)

                        Text(settings.t(.selectLanguageSubtitle))
                            .font(.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: AppSpacing.medium) {
                    ForEach(languages) { language in
                        languageButton(language)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.large)
        }
        .background(AppScreenBackground())
        .onAppear {
            if let code = settings.countryCode {
                languages = Queries.getLanguagesForCountry(Database.shared, code)
            }
        }
    }

    private var introCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.heroGradient)

            RouteRibbon()
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack(spacing: 7) {
                    Text("FR")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Theme.routeBlue, in: RoundedRectangle(cornerRadius: 5))
                    Text(settings.countryName.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .foregroundStyle(.white.opacity(0.78))
                }

                Text(settings.t(.appName))
                    .font(.display(34, .bold))
                    .foregroundStyle(.white)

                Text(settings.t(.splashSubtitle))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(24)
        }
        .frame(minHeight: 180)
        .shadow(color: Theme.routeBlueDeep.opacity(0.24), radius: 20, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func languageButton(_ language: Language) -> some View {
        Button {
            AppFeedback.selection()
            settings.chooseLanguage(language.code)
        } label: {
            HStack(spacing: AppSpacing.standard) {
                Text(language.code.rawValue.uppercased())
                    .font(.gauge(13, .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.buttonGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)

                Text(language.name)
                    .font(.headline)
                    .foregroundStyle(AppColor.text)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: AppSpacing.small)

                Image(systemName: "chevron.forward")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.standard)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(AppColor.surface)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .stroke(AppColor.separator, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .shadow(color: Theme.routeBlueDeep.opacity(0.05), radius: 12, y: 5)
        .accessibilityLabel(language.name)
        .accessibilityHint(settings.t(.selectLanguageActionHint))
    }
}

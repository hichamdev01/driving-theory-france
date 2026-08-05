import SwiftUI

struct SelectLanguageView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var languages: [Language] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HStack(alignment: .top, spacing: AppSpacing.standard) {
                    LearningRouteMark()

                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Image(systemName: "road.lanes")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppColor.action)
                            .accessibilityHidden(true)

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
        .background(AppColor.background.ignoresSafeArea())
        .onAppear {
            if let code = settings.countryCode {
                languages = Queries.getLanguagesForCountry(Database.shared, code)
            }
        }
    }

    private func languageButton(_ language: Language) -> some View {
        Button {
            settings.chooseLanguage(language.code)
        } label: {
            HStack(spacing: AppSpacing.standard) {
                Image(systemName: "character.bubble")
                    .font(.title3)
                    .foregroundStyle(AppColor.action)
                    .frame(width: 28)
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
        .accessibilityLabel(language.name)
        .accessibilityHint(settings.t(.selectLanguageActionHint))
    }
}

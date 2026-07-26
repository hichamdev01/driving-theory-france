import SwiftUI

struct SelectLanguageView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var languages: [Language] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "road.lanes")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.buttonGradient)
                    .padding(.top, 24)
                Text(settings.t(.selectLanguageTitle))
                    .font(.display(26, .bold))
                    .foregroundColor(Theme.text)
                Text(settings.t(.selectLanguageSubtitle))
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textMuted)

                ForEach(Array(languages.enumerated()), id: \.element.id) { i, language in
                    CardView(action: { settings.chooseLanguage(language.code) }) {
                        Text(language.name)
                            .font(.display(18, .semibold))
                            .foregroundColor(Theme.text)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 4)
                    .appear(i)
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            if let code = settings.countryCode {
                languages = Queries.getLanguagesForCountry(Database.shared, code)
            }
        }
    }
}

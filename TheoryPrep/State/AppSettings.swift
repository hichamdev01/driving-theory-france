import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @Published var loading = true
    @Published var countryCode: CountryCode? = .FR
    @Published var languageCode: LanguageCode?

    private let db = Database.shared

    let countryName = "France"

    func load() {
        Seeder.seedIfNeeded(db)
        let settings = Queries.getUserSettings(db)
        languageCode = settings.selectedLanguageCode
        loading = false
    }

    func chooseLanguage(_ code: LanguageCode) {
        Queries.setSelectedLanguage(db, code)
        languageCode = code
    }

    func resetLanguage() {
        languageCode = nil
    }

    func t(_ key: StringKey, _ args: CVarArg...) -> String {
        localizedString(key, languageCode, arguments: args)
    }

    func t(_ key: StringKey, count: Int) -> String {
        localizedString(key, languageCode, arguments: ["\(count)"])
    }
}

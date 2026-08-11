# TheoryPrep — native SwiftUI app

This repository is a native SwiftUI iPhone app (iOS 17+), not an Expo/React
Native project. `README.md`'s Expo description is historical and does not
describe the current codebase — do not migrate this app to Expo/React Native.

Source of truth:

- `project.yml` — XcodeGen project definition. Regenerate the `.xcodeproj`
  with `xcodegen generate` after changing it.
- `TheoryPrep/**/*.swift` — app code (`App/` entry point + theme, `Views/`,
  `Components/`, `Database/` (SQLite), `Models/`, `Localization/`, `State/`).
- Content and user progress are stored locally in SQLite; there is no backend.

When making UI changes, use the shared design system in `TheoryPrep/App/Theme.swift`
(`AppColor`, `AppSpacing`, `AppRadius`, `Theme`) and the shared components in
`TheoryPrep/Components/` rather than one-off styling.

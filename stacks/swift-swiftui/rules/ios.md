---
globs: "**/*.swift"
---

# Swift / SwiftUI Rules

## Stack
Swift 5.9+, SwiftUI, iOS 17+. @Observable (not @ObservableObject for new code). Native async/await. SPM for dependencies.

## Patterns
- MVVM: @Observable ViewModel + SwiftUI View
- @MainActor on ViewModels that update UI
- Native URLSession for networking. No Alamofire without justification.
- Codable for JSON parsing. JSONDecoder with `keyDecodingStrategy: .convertFromSnakeCase`
- UserDefaults for simple config. Keychain for secrets.

## Navigation
- NavigationStack (not NavigationView)
- @Environment(\.dismiss) for pop
- Deep links via .onOpenURL

## Error handling
- do/catch with specific error types, not generic
- Alert/toast for user-facing errors
- Silent log for recoverable errors

## Conventions
- Timeouts: 30s request, 300s resource
- SSE: exponential backoff with max 30s

## Build
- `open *.xcodeproj` or `open *.xcworkspace` (Xcode 15+)
- `swift build` for SPM packages
- `xcodebuild -scheme <name> -sdk iphonesimulator build` for CI

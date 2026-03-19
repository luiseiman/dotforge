---
globs: "**/*.swift"
---

# Swift / SwiftUI Rules

## Stack
Swift 5.9+, SwiftUI, iOS 17+. @Observable (no @ObservableObject para nuevos). async/await nativo. SPM para dependencias.

## Patterns
- MVVM: @Observable ViewModel + SwiftUI View
- @MainActor en ViewModels que actualizan UI
- URLSession nativo para networking. No Alamofire salvo justificación.
- Codable para JSON parsing. JSONDecoder con `keyDecodingStrategy: .convertFromSnakeCase`
- UserDefaults para config simple. Keychain para secrets.

## Navigation
- NavigationStack (no NavigationView)
- @Environment(\.dismiss) para pop
- Deep links via .onOpenURL

## Error handling
- do/catch con tipos de error específicos, no genéricos
- Alert/toast para errores de usuario
- Log silencioso para errores recuperables

## Convenciones
- UI en español (si el usuario es hispanohablante)
- Timeouts: 30s request, 300s resource
- SSE: exponential backoff con max 30s

## Build
- `open *.xcodeproj` o `open *.xcworkspace` (Xcode 15+)
- `swift build` para SPM packages
- `xcodebuild -scheme <name> -sdk iphonesimulator build` para CI

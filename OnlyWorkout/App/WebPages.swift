import Foundation

/// The owner's pages App Review requires and the app links to from Settings (README §14); their
/// sources are in `site/onlyworkout/`.
enum WebPages {
    static let privacyPolicy = URL(string: "https://stefanblos.com/onlyworkout/privacy/")!
    static let support = URL(string: "https://stefanblos.com/onlyworkout/support/")!
}

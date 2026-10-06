import CryptoKit
import Foundation

/// A one-time value whose hash Sign in with Apple puts into the ID token, so Supabase can tell the
/// token was issued for this sign-in and not replayed.
struct AppleSignInNonce {
    let raw = (0..<32).map { _ in String(format: "%02x", UInt8.random(in: .min ... .max)) }.joined()

    var hashed: String {
        SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

import Foundation

/// What `CloudSync` needs from Supabase; `SupabaseBackend` is the real one.
@MainActor
public protocol CloudBackend: AnyObject {
    var isSignedIn: Bool { get }
    /// Exchanges a Sign in with Apple ID token for a Supabase session.
    func signIn(appleIDToken: String, nonce: String) async throws
    func signOut() async throws
    /// Revokes the Apple token and deletes the user with all their rows (`delete-account`).
    func deleteAccount(appleAuthorizationCode: String) async throws
    /// Sends the JSON of `CloudCoding.encodePush` to `sync_push`.
    func push(_ payload: Data) async throws
    /// The raw answer of `sync_pull`; `nil` pulls everything.
    func pull(since: Date?) async throws -> Data
}

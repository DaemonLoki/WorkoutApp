import Foundation
import Supabase

/// The real cloud: Supabase Auth with Sign in with Apple, the sync RPCs and `delete-account`;
/// the Strava calls are in `SupabaseBackend+Strava.swift`.
@MainActor
public final class SupabaseBackend: CloudBackend {
    let client: SupabaseClient

    public init(url: URL, publishableKey: String) {
        client = SupabaseClient(
            supabaseURL: url, supabaseKey: publishableKey,
            options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true)))
    }

    public var isSignedIn: Bool {
        client.auth.currentSession != nil
    }

    public func signIn(appleIDToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(provider: .apple, idToken: appleIDToken, nonce: nonce))
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func deleteAccount(appleAuthorizationCode: String) async throws {
        try await client.functions.invoke(
            "delete-account", options: FunctionInvokeOptions(body: ["authorization_code": appleAuthorizationCode]))
        // The user no longer exists on the server; only the local session is left to clear.
        try? await client.auth.signOut(scope: .local)
    }

    public func push(_ payload: Data) async throws {
        let json = try JSONDecoder().decode(AnyJSON.self, from: payload)
        try await client.rpc("sync_push", params: ["payload": json]).execute()
    }

    public func pull(since: Date?) async throws -> Data {
        let params: [String: String?] = ["since": since.map(CloudCoding.timestamp)]
        return try await client.rpc("sync_pull", params: params).execute().data
    }
}

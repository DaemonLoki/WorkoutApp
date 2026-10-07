import Foundation
import OnlyWorkoutStore
import OnlyWorkoutSync

/// Cloud Sync and Strava, both talking to the Supabase project named in Info.plist
/// (from `Config/Secrets.xcconfig`).
struct CloudServices {
    let sync: CloudSync
    let strava: StravaLink

    /// `nil` when the build has no Supabase configuration, so the app stays local-only.
    static func configured(log: TrainingLog) -> CloudServices? {
        let info = Bundle.main.infoDictionary ?? [:]
        guard let address = info["SupabaseURL"] as? String, let url = URL(string: address), url.host() != nil,
            let key = info["SupabasePublishableKey"] as? String, !key.isEmpty
        else { return nil }
        let backend = SupabaseBackend(url: url, publishableKey: key)
        let creator = info["CFBundleDisplayName"] as? String ?? "OnlyWorkout"
        return CloudServices(
            sync: CloudSync(log: log, backend: backend), strava: StravaLink(log: log, backend: backend, creator: creator))
    }

    /// The Strava API app's client ID (not secret); `nil` until `STRAVA_CLIENT_ID` is in `Secrets.xcconfig`.
    static var stravaClientID: String? {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "StravaClientID") as? String, !id.isEmpty else {
            return nil
        }
        return id
    }
}

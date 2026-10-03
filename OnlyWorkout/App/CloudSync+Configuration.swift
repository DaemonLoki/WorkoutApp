import Foundation
import OnlyWorkoutStore
import OnlyWorkoutSync

extension CloudSync {
    /// Connects to the Supabase project named in Info.plist (from `Config/Secrets.xcconfig`);
    /// `nil` when the build has none, so the app stays local-only.
    static func configured(log: TrainingLog) -> CloudSync? {
        let info = Bundle.main.infoDictionary ?? [:]
        guard let address = info["SupabaseURL"] as? String, let url = URL(string: address), url.host() != nil,
            let key = info["SupabasePublishableKey"] as? String, !key.isEmpty
        else { return nil }
        return CloudSync(log: log, backend: SupabaseBackend(url: url, publishableKey: key))
    }
}

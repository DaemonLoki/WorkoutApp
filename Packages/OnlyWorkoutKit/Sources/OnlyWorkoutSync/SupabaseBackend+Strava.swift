import Foundation
import Supabase
import os

/// The `strava-*` Edge Functions and the connection RPCs (supabase/migrations, README §12).
extension SupabaseBackend: StravaBackend {
    public func stravaConnection() async throws -> StravaConnection? {
        let data = try await client.rpc("strava_connection").execute().data
        return try Self.stravaDecoder.decode(StravaConnection?.self, from: data)
    }

    public func stravaConnectOpen() async throws -> Bool {
        try await client.rpc("strava_connect_open").execute().value
    }

    public func connectStrava(authorizationCode: String) async throws -> StravaConnection {
        try await invokeStrava("strava-connect", body: ["code": AnyJSON.string(authorizationCode)])
    }

    public func setStravaAutoUpload(_ isOn: Bool) async throws {
        try await client.rpc("set_strava_auto_upload", params: ["is_on": isOn]).execute()
    }

    public func disconnectStrava() async throws {
        let _: AnyJSON = try await invokeStrava("strava-disconnect", body: [:])
    }

    public func uploadToStrava(_ upload: StravaUploadRequest) async throws -> StravaUploadOutcome {
        let body: [String: AnyJSON] = [
            "session_id": .string(upload.sessionID.uuidString.lowercased()),
            "name": .string(upload.name),
            "file": try JSONDecoder().decode(AnyJSON.self, from: upload.file),
        ]
        let answer: UploadAnswer = try await invokeStrava("strava-upload", body: body)
        return answer.activityID.map { .uploaded(activityID: $0) } ?? .stillProcessing
    }

    private struct UploadAnswer: Decodable {
        var activityID: Int64?
    }

    /// Turns the functions' error codes (supabase/functions/_shared/connections.ts) into `StravaBackendError`.
    private func invokeStrava<Answer: Decodable>(_ name: String, body: [String: AnyJSON]) async throws -> Answer {
        do {
            return try await client.functions.invoke(
                name, options: FunctionInvokeOptions(body: body), decoder: Self.stravaDecoder)
        } catch FunctionsError.httpError(let code, let data) {
            let failure = try? Self.stravaDecoder.decode(Failure.self, from: data)
            Logger.strava.error(
                "\(name, privacy: .public) answered \(code): \(String(decoding: data, as: UTF8.self), privacy: .public)"
            )
            switch (code, failure?.error) {
            case (404, "not_connected"): throw StravaBackendError.notConnected
            case (409, "athlete_limit"): throw StravaBackendError.athleteLimitReached
            case (422, _): throw StravaBackendError.rejected(detail: failure?.detail ?? "")
            default: throw StravaBackendError.unavailable
            }
        } catch {
            Logger.strava.error("\(name, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    private struct Failure: Decodable {
        var error: String
        var detail: String?
    }

    private static let stravaDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = CloudCoding.date(fromPostgres: text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a timestamp: \(text)")
            }
            return date
        }
        return decoder
    }()
}

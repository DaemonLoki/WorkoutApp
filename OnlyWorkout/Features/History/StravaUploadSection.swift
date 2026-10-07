import OnlyWorkoutStore
import OnlyWorkoutSync
import SwiftUI
import os

/// Session detail → Strava: whether the Session is on Strava, a link to it for 7 days, or a manual upload.
struct StravaUploadSection: View {
    let session: Session
    let strava: StravaLink?
    @State private var failure: LocalizedStringResource?

    var body: some View {
        if let uploadedAt = session.stravaUploadedAt {
            Section {
                LabeledContent {
                    Text(uploadedAt, format: .dateTime.day().month().hour().minute())
                } label: {
                    Text(.uploadedToStrava)
                }
                if let url = activityURL(uploadedAt: uploadedAt) {
                    // Strava's brand guidelines: exactly "View on Strava", marked as a link.
                    Link(destination: url) {
                        Text(.viewOnStrava).bold()
                    }
                }
            }
        } else if let strava, case .connected = strava.status, !session.isInProgress {
            Section {
                Button {
                    upload(strava)
                } label: {
                    LabeledContent {
                        if strava.uploading.contains(session.id) { ProgressView() }
                    } label: {
                        Text(.uploadToStrava)
                    }
                }
                .disabled(strava.uploading.contains(session.id))
            }
            .alert(Text(.stravaUploadFailed), isPresented: isFailing) {
                Button(.close, role: .cancel) {}
            } message: {
                if let failure { Text(failure) }
            }
        }
    }

    /// Strava's activity ID is kept for 7 days only (Strava API Policy §6.2).
    private func activityURL(uploadedAt: Date) -> URL? {
        guard let id = session.stravaActivityID,
            Date.now.timeIntervalSince(uploadedAt) < Session.stravaActivityIDLifetime
        else { return nil }
        return URL(string: "https://www.strava.com/activities/\(id)")
    }

    private var isFailing: Binding<Bool> {
        Binding {
            failure != nil
        } set: {
            if !$0 { failure = nil }
        }
    }

    private func upload(_ strava: StravaLink) {
        Task {
            do {
                try await strava.upload(session)
            } catch StravaLink.UploadError.nothingToUpload {
                failure = .stravaNothingToUpload
            } catch StravaLink.UploadError.stillProcessing {
                failure = .stravaStillProcessing
            } catch StravaBackendError.notConnected {
                failure = .stravaNotConnectedAnyMore
            } catch {
                Logger.strava.error("Upload failed: \(String(describing: error), privacy: .public)")
                failure = .stravaTryAgainLater
            }
        }
    }
}

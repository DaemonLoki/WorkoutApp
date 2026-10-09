import OnlyWorkoutDesign
import SwiftUI

/// The Welcome Tour: a welcome and five pages of live demos, swipeable, with a visible Continue for those who don't
/// swipe. Used by onboarding (Skip jumps to setup) and replayed from Settings → About (README §7 Onboarding).
struct TourView: View {
    /// The bottom button on the first page: Get Started in onboarding, Continue when replayed.
    var startTitle: LocalizedStringResource = .getStarted
    /// The bottom button on the last page: Continue in onboarding, Done when replayed.
    let finishTitle: LocalizedStringResource
    /// The toolbar button: Skip in onboarding, Done when replayed.
    let leaveTitle: LocalizedStringResource
    let onFinish: () -> Void
    @State private var page = TourPage.welcome
    @AccessibilityFocusState private var focusedPage: TourPage?

    var body: some View {
        TabView(selection: $page) {
            ForEach(TourPage.allCases) { page in
                TourPageView(page: page, focusedPage: $focusedPage) {
                    demo(for: page)
                }
                .tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: DesignTokens.Spacing.l) {
                PageIndicator(count: TourPage.allCases.count, current: page.rawValue)
                OnboardingButton(title: buttonTitle) {
                    if let next = page.next {
                        withAnimation(DesignTokens.Motion.step) { page = next }
                    } else {
                        onFinish()
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.bottom, DesignTokens.Spacing.s)
            .frame(maxWidth: DesignTokens.Size.readableWidth)
            .accessibilityIdentifier("tourContinueButton")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(leaveTitle, action: onFinish)
                    .accessibilityIdentifier("tourLeaveButton")
            }
        }
        .onChange(of: page) { focusedPage = page }
    }

    private var buttonTitle: LocalizedStringResource {
        switch page {
        case .welcome: startTitle
        case .sync: finishTitle
        default: .continueLabel
        }
    }

    @ViewBuilder
    private func demo(for page: TourPage) -> some View {
        let isActive = self.page == page
        switch page {
        case .welcome: StepUpPlateMark()
        case .plan: NextUpDemo(isActive: isActive)
        case .logSet: LogSetDemo(isActive: isActive)
        case .stepUp: StepUpDemo(isActive: isActive)
        case .watch: WatchDemo(isActive: isActive)
        case .sync: SyncDemo(isActive: isActive)
        }
    }
}

#Preview {
    NavigationStack {
        TourView(finishTitle: .continueLabel, leaveTitle: .skip) {}
    }
}

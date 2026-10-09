import OnlyWorkoutDesign
import SwiftUI

/// The frame of every onboarding setup page: a header, a large title with a sentence or two, optional content,
/// and the page's buttons pinned to the bottom (README §7 Onboarding). Scrolls at large text sizes.
struct OnboardingPage<Header: View, Content: View, Actions: View>: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    /// Short pages sit in the middle of the screen; long ones start at the top.
    var centersContent = true
    @ViewBuilder let header: Header
    @ViewBuilder let content: Content
    @ViewBuilder let actions: Actions
    @AccessibilityFocusState private var focusesTitle: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.l) {
                header
                VStack(spacing: DesignTokens.Spacing.s) {
                    Text(title)
                        .font(.largeTitle.bold())
                    Text(message)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($focusesTitle)
                content
            }
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.vertical, DesignTokens.Spacing.l)
            .frame(maxWidth: DesignTokens.Size.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(centersContent ? .center : .top, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: DesignTokens.Spacing.s) {
                actions
            }
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.bottom, DesignTokens.Spacing.s)
            .frame(maxWidth: DesignTokens.Size.readableWidth)
        }
        .onAppear { focusesTitle = true }
    }
}

extension OnboardingPage where Content == EmptyView {
    init(
        title: LocalizedStringResource, message: LocalizedStringResource, @ViewBuilder header: () -> Header,
        @ViewBuilder actions: () -> Actions
    ) {
        self.init(title: title, message: message, header: header, content: { EmptyView() }, actions: actions)
    }
}

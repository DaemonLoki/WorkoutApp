import OnlyWorkoutDesign
import SwiftUI

/// One Welcome Tour page: a live demo above, the title and a sentence or two below. The caption alone carries the
/// message, so VoiceOver reads it as one element and skips the demo; at accessibility text sizes the demo makes room.
struct TourPageView<Demo: View>: View {
    let page: TourPage
    var focusedPage: AccessibilityFocusState<TourPage?>.Binding
    @ViewBuilder let demo: Demo
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                caption
                    .padding(DesignTokens.Spacing.l)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center, for: .alignment)
        } else if page == .welcome {
            // The mark and its words belong together, a little above the middle.
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()
                demo
                    .accessibilityHidden(true)
                caption
                Spacer()
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.l)
            .frame(maxWidth: DesignTokens.Size.readableWidth)
        } else {
            VStack(spacing: DesignTokens.Spacing.xl) {
                demo
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityHidden(true)
                caption
            }
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.vertical, DesignTokens.Spacing.m)
            .frame(maxWidth: DesignTokens.Size.readableWidth)
        }
    }

    private var caption: some View {
        VStack(spacing: DesignTokens.Spacing.s) {
            Text(page.title)
                .font(page == .welcome ? .largeTitle.bold() : .title.bold())
            Text(page.message)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityFocused(focusedPage, equals: page)
    }
}

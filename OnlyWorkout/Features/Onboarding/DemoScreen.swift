import OnlyWorkoutDesign
import SwiftUI

/// A miniature app screen for the Welcome Tour: lays real app views out at a phone's size and scales them to fit,
/// so a demo looks the same on every iPhone. Text inside keeps the default size; the page's caption scales instead.
struct DemoScreen<Content: View>: View {
    /// The logical size the content is laid out at.
    static var size: CGSize { CGSize(width: 330, height: 620) }
    /// The screen behind the content; Today's list uses the grouped background.
    var screen: Color = Color(.secondarySystemBackground)
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: DesignTokens.Radius.demoScreen, style: .continuous)
        GeometryReader { proxy in
            let scale = min(proxy.size.width / Self.size.width, proxy.size.height / Self.size.height, 1)
            content
                .padding(DesignTokens.Spacing.m)
                .frame(width: Self.size.width, height: Self.size.height)
                .background(screen, in: shape)
                .overlay { shape.strokeBorder(.quaternary, lineWidth: 1) }
                .clipShape(shape)
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .dynamicTypeSize(.large)
    }
}

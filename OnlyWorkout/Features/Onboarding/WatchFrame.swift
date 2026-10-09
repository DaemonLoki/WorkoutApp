import OnlyWorkoutDesign
import SwiftUI

/// A simple watch shape for the Welcome Tour: a rounded case with a crown, dark screen inside. Deliberately no
/// product rendering.
struct WatchFrame<Content: View>: View {
    @ViewBuilder let content: Content

    // A drawing's proportions, close to a 46 mm Apple Watch screen in points (208 × 248), a little smaller.
    /// The whole drawing, case and crown included.
    static var size: CGSize {
        CGSize(width: screen.width + 2 * bezel + crown.width / 2, height: screen.height + 2 * bezel)
    }

    private static var screen: CGSize { CGSize(width: 184, height: 224) }
    private static var screenRadius: Double { 50 }
    private static var bezel: Double { 10 }
    private static var crown: CGSize { CGSize(width: 10, height: 40) }

    var body: some View {
        content
            .frame(width: Self.screen.width, height: Self.screen.height)
            .background(.black, in: .rect(cornerRadius: Self.screenRadius, style: .continuous))
            .padding(Self.bezel)
            .background(Color(white: 0.16), in: .rect(cornerRadius: Self.screenRadius + Self.bezel, style: .continuous))
            .overlay(alignment: .trailing) {
                Capsule()
                    .fill(Color(white: 0.24))
                    .frame(width: Self.crown.width, height: Self.crown.height)
                    .offset(x: Self.crown.width / 2, y: -Self.screen.height * 0.15)
            }
            .environment(\.colorScheme, .dark)
    }
}

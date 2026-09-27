import SwiftUI

extension View {
    /// The rounded, quiet surface used for cards across the app.
    public func cardBackground() -> some View {
        padding(DesignTokens.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: .rect(cornerRadius: DesignTokens.Radius.card))
    }
}

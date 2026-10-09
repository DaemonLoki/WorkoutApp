import SwiftUI

/// A neutral symbol on a small rounded tile, like the icons in Settings rows.
struct SymbolTile: View {
    let systemName: String
    var size: Double = 29

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(.fill.tertiary, in: .rect(cornerRadius: size * 0.225, style: .continuous))
            .accessibilityHidden(true)
    }
}

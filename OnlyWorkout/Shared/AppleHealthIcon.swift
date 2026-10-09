import SwiftUI

/// Stands for Apple Health wherever the app names it. The HIG asks for Apple's own Apple Health icon and forbids
/// look-alikes, so until that asset is in the catalog (DaemonLoki/WorkoutApp#37) this is a neutral symbol, not a heart.
struct AppleHealthIcon: View {
    var size: Double = 29

    var body: some View {
        SymbolTile(systemName: "waveform.path.ecg", size: size)
    }
}

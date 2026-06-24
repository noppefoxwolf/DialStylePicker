import SwiftUI

#Preview {
    PreviewContent()
}

private struct PreviewContent: View {
    @State
    private var selection = 0

    var body: some View {
        VStack {
            DialStylePicker(selection: $selection) {
                Label("ビデオ", systemImage: "video")
                    .tag(0)
                    .dialStylePickerGroup("capture")
                Text("写真")
                    .tag(1)
                    .dialStylePickerGroup("capture")
                Text("ライブ")
                    .tag(2)
                Text("ポートレート")
                    .tag(3)
                Text("シネマティック")
                    .tag(4)
            }
        }
        .preferredColorScheme(.dark)
    }
}

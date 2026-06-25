import SwiftUI
import DialStylePicker

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleScreen()
        }
    }
}

private struct ExampleScreen: View {
    @State
    private var selectedCaptureMode = "photo"

    var body: some View {
        DialStylePicker(selection: $selectedCaptureMode) {
            Label("Video", systemImage: "video")
                .labelStyle(.titleAndIcon)
                .tag("video")
                .dialStylePickerGroup("capture")

            Label("Photo", systemImage: "camera")
                .labelStyle(.titleAndIcon)
                .tag("photo")
                .dialStylePickerGroup("capture")

            Label("Live", systemImage: "livephoto")
                .labelStyle(.titleAndIcon)
                .tag("live")

            Label("Portrait", systemImage: "person.crop.rectangle")
                .labelStyle(.titleAndIcon)
                .tag("portrait")

            Label("Cinematic", systemImage: "sparkles.tv")
                .labelStyle(.titleAndIcon)
                .tag("cinematic")
        }
    }
}

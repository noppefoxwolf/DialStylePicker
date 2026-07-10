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

    @State
    private var selectedLensMode = "wide"

    private let captureModes = [
        "video",
        "photo",
        "live",
        "portrait",
        "cinematic",
    ]

    private let lensModes = [
        "Camera",
        "Video",
    ]

    var body: some View {
        VStack(spacing: 24) {
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

            Picker("Selection", selection: $selectedCaptureMode) {
                ForEach(captureModes, id: \.self) { mode in
                    Text(mode.capitalized)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            DialStylePicker(selection: $selectedLensMode) {
                Label("Camera", systemImage: "camera")
                    .labelStyle(.titleOnly)
                    .tag("wide")
                    .dialStylePickerGroup("lens")

                Label("Video", systemImage: "camera.aperture")
                    .labelStyle(.titleOnly)
                    .tag("telephoto")
                    .dialStylePickerGroup("lens")
            }

            Picker("Lens", selection: $selectedLensMode) {
                ForEach(lensModes, id: \.self) { mode in
                    Text(mode.capitalized)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
}

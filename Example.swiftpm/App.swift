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
    private var selectedDay = 3

    @State
    private var selectedCategory = Category.trending

    @State
    private var selectedCaptureMode = CaptureMode.photo

    private let days = [
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
        "Sat",
        "Sun",
        "Holiday",
        "Workday",
    ]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Example")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 32) {
                header
                taggedSelectionDemo
                groupedSegmentDemo
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(.background.secondary)
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("DialStylePicker")
                .font(.largeTitle.bold())
            Text("Tap a segment or drag the picker horizontally.")
                .foregroundStyle(.secondary)
        }
    }

    private var taggedSelectionDemo: some View {
        DemoSection(title: "Tagged custom content") {
            VStack(alignment: .center, spacing: 16) {
                selectionLabel("Selected category", value: selectedCategory.title)

                DialStylePicker(selection: $selectedCategory) {
                    ForEach(Category.allCases) { category in
                        Label(category.title, systemImage: category.systemImage)
                            .labelStyle(.titleAndIcon)
                            .tag(category)
                    }
                }
            }
        }
    }

    private var groupedSegmentDemo: some View {
        DemoSection(title: "Grouped segments") {
            VStack(alignment: .center, spacing: 16) {
                selectionLabel("Selected capture mode", value: selectedCaptureMode.title)

                DialStylePicker(selection: $selectedCaptureMode) {
                    ForEach(CaptureMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage)
                            .labelStyle(.titleAndIcon)
                            .tag(mode)
                            .dialStylePickerGroup(mode.groupID)
                    }
                }
            }
        }
    }

    private func selectionLabel(_ title: LocalizedStringKey, value: String) -> some View {
        LabeledContent(title) {
            Text(value)
                .font(.headline)
        }
    }
}

private struct DemoSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder
    let content: Content

    var body: some View {
        section
    }

    private var section: some View {
        VStack(alignment: .center, spacing: 20) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private enum CaptureMode: String, CaseIterable, Identifiable {
    case video
    case photo
    case live
    case portrait
    case cinematic

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .video:
            "Video"
        case .photo:
            "Photo"
        case .live:
            "Live"
        case .portrait:
            "Portrait"
        case .cinematic:
            "Cinematic"
        }
    }

    var systemImage: String {
        switch self {
        case .video:
            "video"
        case .photo:
            "camera"
        case .live:
            "livephoto"
        case .portrait:
            "person.crop.rectangle"
        case .cinematic:
            "sparkles.tv"
        }
    }

    var groupID: String {
        switch self {
        case .video, .photo:
            "capture"
        default:
            rawValue
        }
    }
}

private enum Category: String, CaseIterable, Identifiable {
    case latest
    case trending
    case favorites
    case archived
    case drafts
    case shared

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .latest:
            "Latest"
        case .trending:
            "Trending"
        case .favorites:
            "Favorites"
        case .archived:
            "Archived"
        case .drafts:
            "Drafts"
        case .shared:
            "Shared"
        }
    }

    var systemImage: String {
        switch self {
        case .latest:
            "clock"
        case .trending:
            "chart.line.uptrend.xyaxis"
        case .favorites:
            "star"
        case .archived:
            "archivebox"
        case .drafts:
            "doc.text"
        case .shared:
            "person.2"
        }
    }
}

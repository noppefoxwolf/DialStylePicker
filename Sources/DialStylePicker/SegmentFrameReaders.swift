import SwiftUI

struct SegmentFramesPreferenceKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

struct SegmentGroupFramesPreferenceKey: PreferenceKey {
    static let defaultValue: [SegmentGroupKey: CGRect] = [:]

    static func reduce(value: inout [SegmentGroupKey: CGRect], nextValue: () -> [SegmentGroupKey: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

struct ViewportReader<Content: View>: View {
    let content: (CGFloat) -> Content

    var body: some View {
        GeometryReader { proxy in
            content(proxy.size.width)
        }
    }
}

struct SegmentFrameReader: View {
    let id: Int
    let coordinateSpaceName: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: SegmentFramesPreferenceKey.self,
                value: [id: proxy.frame(in: .named(coordinateSpaceName))]
            )
        }
    }
}

struct SegmentGroupFrameReader: View {
    let key: SegmentGroupKey
    let coordinateSpaceName: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: SegmentGroupFramesPreferenceKey.self,
                value: [key: proxy.frame(in: .named(coordinateSpaceName))]
            )
        }
    }
}

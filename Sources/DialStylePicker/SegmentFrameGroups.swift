import SwiftUI

enum SegmentGroupKey: Hashable {
    case single(Int)
    case grouped(DialStylePickerGroupID)
}

enum HorizontalEdge {
    case leading
    case trailing
}

struct SegmentFrameState {
    var frames: [Int: CGRect] = [:]
    var groupedFrames: [SegmentGroupKey: CGRect] = [:]
    var groupContainerFrames: [SegmentGroupKey: CGRect] = [:]
    var segmentFrameKeys: [Int: SegmentGroupKey] = [:]
    var viewportWidth: CGFloat = 0
}

struct SegmentInteractionState {
    var focusedIndex = 0
    var pendingSelectionIndex: Int?
    var hasScrolledToInitialSelection = false
    var isExpanded = false
    var isScrolling = false
    var showsScrollMask = false
    var tracksSelectionWhileScrolling = false
    var feedbackTrigger = 0
}

struct SegmentScheduledTasks {
    var collapseTask: Task<Void, Never>?
    var selectionTask: Task<Void, Never>?
    var initialScrollTask: Task<Void, Never>?
}

struct SegmentFrameGroups {
    var frames: [Int: CGRect]
    var groupedFrames: [SegmentGroupKey: CGRect]
    var segmentFrameKeys: [Int: SegmentGroupKey]

    init(
        frames: [Int: CGRect],
        groupedFrames: [SegmentGroupKey: CGRect],
        segmentFrameKeys: [Int: SegmentGroupKey]
    ) {
        self.frames = frames
        self.groupedFrames = groupedFrames
        self.segmentFrameKeys = segmentFrameKeys
    }

    init(
        frames: [Int: CGRect],
        groupContainerFrames: [SegmentGroupKey: CGRect],
        subviews: SubviewsCollection
    ) {
        let keysByIndex = Dictionary(uniqueKeysWithValues: subviews.indices.map { index in
            (
                index,
                subviews[index].containerValues.dialStylePickerGroupID.map(SegmentGroupKey.grouped) ?? .single(index)
            )
        })

        let groups = Dictionary(grouping: subviews.indices) { index in
            keysByIndex[index] ?? .single(index)
        }

        let groupedFrames = groups.compactMapValues { indices in
            let key = keysByIndex[indices.first ?? -1]

            if let key, let groupContainerFrame = groupContainerFrames[key] {
                return groupContainerFrame
            }

            return indices
                .compactMap { frames[$0] }
                .reduce(nil) { partialResult, frame in
                    partialResult?.union(frame) ?? frame
                }
        }

        self.init(
            frames: frames,
            groupedFrames: groupedFrames,
            segmentFrameKeys: keysByIndex
        )
    }

    func focusedFrame(for index: Int) -> CGRect? {
        let key = frameGroupKey(for: index)
        return groupedFrames[key] ?? frames[index]
    }

    func frameGroupKey(for index: Int) -> SegmentGroupKey {
        segmentFrameKeys[index] ?? .single(index)
    }

    func scrollTarget(for index: Int) -> SegmentGroupKey {
        let key = frameGroupKey(for: index)
        switch key {
        case .single(let index):
            return .single(index)
        case .grouped:
            return key
        }
    }

    func scrollAnchor(for index: Int) -> UnitPoint {
        let target = scrollTarget(for: index)

        guard
            let groupFrame = groupedFrames[frameGroupKey(for: index)],
            let targetFrame = groupedFrames[target],
            targetFrame.width > 0
        else {
            return .center
        }

        return UnitPoint(
            x: (groupFrame.midX - targetFrame.minX) / targetFrame.width,
            y: 0.5
        )
    }

    func centeredSegment(nearestTo centerX: CGFloat) -> Int? {
        guard let centeredGroup = groupedFrames.min(by: { lhs, rhs in
            abs(lhs.value.midX - centerX) < abs(rhs.value.midX - centerX)
        }) else {
            return nil
        }

        return segmentIndex(
            for: centeredGroup.key,
            nearestTo: centerX
        )
    }

    func groupMemberIndices(for key: SegmentGroupKey) -> [Int] {
        segmentFrameKeys
            .filter { $0.value == key }
            .map(\.key)
    }

    private func segmentIndex(
        for key: SegmentGroupKey,
        nearestTo centerX: CGFloat
    ) -> Int? {
        switch key {
        case .single(let index):
            index
        case .grouped:
            groupMemberIndices(for: key)
                .compactMap { index in
                    frames[index].map { (index, $0) }
                }
                .min { lhs, rhs in
                    abs(lhs.1.midX - centerX) < abs(rhs.1.midX - centerX)
                }?
                .0
        }
    }
}

struct SegmentGroup {
    var key: SegmentGroupKey
    var indices: [Int]
}

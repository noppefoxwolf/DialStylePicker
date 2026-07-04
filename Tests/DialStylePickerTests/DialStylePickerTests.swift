import Testing
import SwiftUI
@testable import DialStylePicker

@Suite("SegmentFrameGroups")
struct SegmentFrameGroupsTests {
    @Test func focusedFramePrefersGroupedFrame() {
        let groupID = DialStylePickerGroupID("capture")
        let groupKey = SegmentGroupKey.grouped(groupID)
        let groups = SegmentFrameGroups(
            frames: [
                0: CGRect(x: 10, y: 0, width: 40, height: 44),
                1: CGRect(x: 50, y: 0, width: 60, height: 44),
                2: CGRect(x: 110, y: 0, width: 80, height: 44),
            ],
            groupedFrames: [
                groupKey: CGRect(x: 10, y: 0, width: 100, height: 44),
                .single(2): CGRect(x: 110, y: 0, width: 80, height: 44),
            ],
            segmentFrameKeys: [
                0: groupKey,
                1: groupKey,
                2: .single(2),
            ]
        )

        #expect(groups.focusedFrame(for: 0) == CGRect(x: 10, y: 0, width: 100, height: 44))
        #expect(groups.focusedFrame(for: 1) == CGRect(x: 10, y: 0, width: 100, height: 44))
        #expect(groups.focusedFrame(for: 2) == CGRect(x: 110, y: 0, width: 80, height: 44))
    }

    @Test func missingGroupMetadataFallsBackToSingleSegment() {
        let groups = SegmentFrameGroups(
            frames: [
                3: CGRect(x: 20, y: 0, width: 50, height: 44),
            ],
            groupedFrames: [:],
            segmentFrameKeys: [:]
        )

        #expect(groups.frameGroupKey(for: 3) == .single(3))
        #expect(groups.scrollTarget(for: 3) == .single(3))
        #expect(groups.focusedFrame(for: 3) == CGRect(x: 20, y: 0, width: 50, height: 44))
        #expect(groups.scrollAnchor(for: 3) == .center)
    }

    @Test func scrollAnchorCentersMemberWithinGroupedTarget() {
        let groupID = DialStylePickerGroupID("capture")
        let groupKey = SegmentGroupKey.grouped(groupID)
        let groups = SegmentFrameGroups(
            frames: [
                0: CGRect(x: 20, y: 0, width: 40, height: 44),
                1: CGRect(x: 60, y: 0, width: 80, height: 44),
            ],
            groupedFrames: [
                groupKey: CGRect(x: 20, y: 0, width: 120, height: 44),
            ],
            segmentFrameKeys: [
                0: groupKey,
                1: groupKey,
            ]
        )

        #expect(groups.scrollTarget(for: 0) == groupKey)
        #expect(groups.scrollAnchor(for: 0) == UnitPoint(x: 0.5, y: 0.5))
    }

    @Test func centeredSegmentChoosesNearestMemberInsideNearestGroup() {
        let groupID = DialStylePickerGroupID("capture")
        let groupKey = SegmentGroupKey.grouped(groupID)
        let groups = SegmentFrameGroups(
            frames: [
                0: CGRect(x: 0, y: 0, width: 40, height: 44),
                1: CGRect(x: 40, y: 0, width: 80, height: 44),
                2: CGRect(x: 180, y: 0, width: 60, height: 44),
            ],
            groupedFrames: [
                groupKey: CGRect(x: 0, y: 0, width: 120, height: 44),
                .single(2): CGRect(x: 180, y: 0, width: 60, height: 44),
            ],
            segmentFrameKeys: [
                0: groupKey,
                1: groupKey,
                2: .single(2),
            ]
        )

        #expect(groups.centeredSegment(nearestTo: 95) == 1)
        #expect(groups.centeredSegment(nearestTo: 210) == 2)
    }

    @Test func centralActivationAreaOnlyMatchesMiddleQuarterOfSegment() {
        let groups = SegmentFrameGroups(
            frames: [
                0: CGRect(x: 0, y: 0, width: 80, height: 44),
                1: CGRect(x: 80, y: 0, width: 120, height: 44),
            ],
            groupedFrames: [
                .single(0): CGRect(x: 0, y: 0, width: 80, height: 44),
                .single(1): CGRect(x: 80, y: 0, width: 120, height: 44),
            ],
            segmentFrameKeys: [
                0: .single(0),
                1: .single(1),
            ]
        )

        #expect(groups.segmentWithCentralActivationArea(containing: 29) == nil)
        #expect(groups.segmentWithCentralActivationArea(containing: 30) == 0)
        #expect(groups.segmentWithCentralActivationArea(containing: 50) == 0)
        #expect(groups.segmentWithCentralActivationArea(containing: 51) == nil)
        #expect(groups.segmentWithCentralActivationArea(containing: 125) == 1)
        #expect(groups.segmentWithCentralActivationArea(containing: 155) == 1)
    }

    @Test func groupMemberIndicesReturnsAllMembersForKey() {
        let groupID = DialStylePickerGroupID("capture")
        let groupKey = SegmentGroupKey.grouped(groupID)
        let groups = SegmentFrameGroups(
            frames: [:],
            groupedFrames: [:],
            segmentFrameKeys: [
                0: groupKey,
                1: groupKey,
                2: .single(2),
            ]
        )

        #expect(Set(groups.groupMemberIndices(for: groupKey)) == [0, 1])
        #expect(groups.groupMemberIndices(for: .single(2)) == [2])
    }

    @Test func frameDictionariesCompareApproximately() {
        let frames = [
            0: CGRect(x: 10, y: 0, width: 44, height: 44),
            1: CGRect(x: 54, y: 0, width: 60, height: 44),
        ]

        #expect(frames.isApproximatelyEqual(to: [
            0: CGRect(x: 10.25, y: 0, width: 44.2, height: 44),
            1: CGRect(x: 54, y: 0.1, width: 60, height: 43.75),
        ]))

        #expect(!frames.isApproximatelyEqual(to: [
            0: CGRect(x: 10, y: 0, width: 45, height: 44),
            1: CGRect(x: 54, y: 0, width: 60, height: 44),
        ]))
    }
}

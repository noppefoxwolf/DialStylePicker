import SwiftUI

extension DialStylePicker {
    func picker(subviews: SubviewsCollection) -> some View {
        ScrollViewReader { scrollView in
            let focusedIndex = effectiveFocusedIndex(in: subviews)
            let viewportWidth = layoutWidth(for: focusedIndex)

            scrollableSegments(
                subviews: subviews,
                scrollView: scrollView
            )
                .onAppear {
                    handleAppear(
                        viewportWidth: viewportWidth,
                        subviews: subviews
                    )
                }
                .task(id: viewportWidth) {
                    await Task.yield()
                    handleViewportWidthChange(
                        viewportWidth,
                        subviews: subviews,
                        scrollView: scrollView
                    )
                }
                .onPreferenceChange(SegmentFramesPreferenceKey.self) { newValue in
                    handleSegmentFramesChange(
                        newValue,
                        subviews: subviews,
                        scrollView: scrollView
                    )
                }
                .onPreferenceChange(SegmentGroupFramesPreferenceKey.self) { newValue in
                    handleSegmentGroupFramesChange(
                        newValue,
                        subviews: subviews,
                        scrollView: scrollView
                    )
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    handleScrollPhaseChange(
                        from: oldPhase,
                        to: newPhase,
                        subviews: subviews,
                        scrollView: scrollView
                    )
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.x
                } action: { _, newValue in
                    handleScrollOffsetChange(
                        newValue,
                        subviews: subviews
                    )
                }
                .onChange(of: selection) { _, newValue in
                    handleSelectionChange(
                        newValue,
                        subviews: subviews,
                        scrollView: scrollView
                    )
                }
                .accessibilityAdjustableAction { direction in
                    adjustSelection(
                        direction,
                        subviews: subviews,
                        scrollView: scrollView
                    )
                }
                .padding(pickerContentPadding)
                .background {
                    focusedSegmentBackground(for: focusedIndex)
                }
        }
    }

    func scrollableSegments(
        subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) -> some View {
        ScrollView(.horizontal) {
            segmentRow(
                subviews: subviews,
                scrollView: scrollView
            )
            .scrollTargetLayout()
            .coordinateSpace(.named(coordinateSpaceName))
        }
        .scrollIndicators(.hidden)
    }

    func segmentRow(
        subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) -> some View {
        HStack(spacing: 0) {
            leadingSpacer

            segments(
                subviews: subviews,
                scrollView: scrollView
            )

            trailingSpacer
        }
    }

    var leadingSpacer: some View {
        Color.clear
            .frame(width: leadingEdgePadding)
    }

    var trailingSpacer: some View {
        Color.clear
            .frame(width: trailingEdgePadding)
    }

    func segments(
        subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) -> some View {
        let focusedIndex = effectiveFocusedIndex(in: subviews)

        return ForEach(segmentGroups(in: subviews), id: \.key) { group in
            HStack(spacing: 0) {
                ForEach(group.indices, id: \.self) { index in
                    segmentButton(
                        id: index,
                        subview: subviews[index],
                        focusedIndex: focusedIndex,
                        scrollView: scrollView
                    )
                }
            }
            .id(group.key)
            .background {
                groupFrameReader(for: group.key)
            }
        }
    }

    @ViewBuilder
    func segmentButton(
        id: Int,
        subview: Subview,
        focusedIndex: Int,
        scrollView: ScrollViewProxy
    ) -> some View {
        segmentLabel(
            id: id,
            subview: subview,
            focusedIndex: focusedIndex
        )
        .accessibilityAddTraits(focusedIndex == id ? .isSelected : [])
        .id(id)
        .onTapGesture {
            selectTappedItem(
                id,
                subview: subview,
                scrollView: scrollView
            )
        }
        .background {
            segmentFrameReader(for: id)
        }
    }

    func segmentLabel(
        id: Int,
        subview: Subview,
        focusedIndex: Int
    ) -> some View {
        subview.modifier(
            SegmentLabelModifier(
                isFocused: focusedIndex == id
            )
        )
    }

    func segmentFrameReader(for id: Int) -> some View {
        SegmentFrameReader(
            id: id,
            coordinateSpaceName: coordinateSpaceName
        )
    }

    func groupFrameReader(for key: SegmentGroupKey) -> some View {
        SegmentGroupFrameReader(
            key: key,
            coordinateSpaceName: coordinateSpaceName
        )
    }

    @ViewBuilder
    func focusedSegmentBackground(for focusedIndex: Int) -> some View {
        if let frame = indicatorFrame(for: focusedIndex) {
            Capsule()
                .foregroundStyle(.secondary)
                .frame(width: frame.width, height: frame.height)
                .offset(
                    x: frame.minX - frameState.scrollOffsetX + pickerContentPadding,
                    y: frame.minY + pickerContentPadding
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .animation(indicatorAnimation, value: focusedIndex)
        }
    }

    func pickerMask(width: CGFloat, focusedIndex: Int) -> some View {
        Group {
            if showsScrollMask(for: focusedIndex) {
                scrollMaskGradient
            } else {
                Rectangle()
            }
        }
        .frame(width: width, height: pickerHeight)
    }

    func showsScrollMask(for focusedIndex: Int) -> Bool {
        interactionState.showsScrollMask || collapsedHorizontalInset(for: focusedIndex) > 0
    }

    var scrollMaskGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.12),
                .init(color: .black, location: 0.88),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var leadingEdgePadding: CGFloat {
        edgePadding(for: frameState.frames.keys.min(), edge: .leading)
    }

    var trailingEdgePadding: CGFloat {
        edgePadding(for: frameState.frames.keys.max(), edge: .trailing)
    }

    func edgePadding(
        for index: Int?,
        edge: HorizontalEdge
    ) -> CGFloat {
        guard let index else {
            return 0
        }

        let itemWidth = edgeFrame(for: index, edge: edge)?.width ?? 0
        return max((frameState.viewportWidth - itemWidth) / 2, 0)
    }

    func edgeFrame(
        for index: Int,
        edge: HorizontalEdge
    ) -> CGRect? {
        let edgeKey = edgeGroupKey(for: index, edge: edge)
        return frameState.groupedFrames[edgeKey] ?? frameState.frames[index]
    }

    func edgeGroupKey(
        for index: Int,
        edge: HorizontalEdge
    ) -> SegmentGroupKey {
        let key = currentFrameGroups.frameGroupKey(for: index)

        guard case .grouped = key else {
            return key
        }

        let members = currentFrameGroups.groupMemberIndices(for: key)
        switch edge {
        case .leading:
            return members.min() == index ? key : .single(index)
        case .trailing:
            return members.max() == index ? key : .single(index)
        }
    }

    func pickerWidth(for focusedIndex: Int) -> CGFloat {
        interactionState.isExpanded ? expandedWidth : collapsedWidth(for: focusedIndex)
    }

    var expandedWidth: CGFloat {
        200
    }

    func layoutWidth(for focusedIndex: Int) -> CGFloat {
        max(expandedWidth, collapsedWidth(for: focusedIndex))
    }

    func collapsedWidth(for focusedIndex: Int) -> CGFloat {
        guard let focusedSegmentWidth = focusedSegmentFrame(for: focusedIndex)?.width else {
            return expandedWidth
        }

        return focusedSegmentWidth + collapsedHorizontalInset(for: focusedIndex) * 2 + pickerContentPadding * 2
    }

    func collapsedHorizontalInset(for focusedIndex: Int) -> CGFloat {
        let frameGroups = currentFrameGroups
        switch frameGroups.frameGroupKey(for: focusedIndex) {
        case .single:
            return 20
        case .grouped(let groupID):
            return frameGroups.groupMemberIndices(for: .grouped(groupID)).count > 1 ? 0 : 20
        }
    }

    var currentFrameGroups: SegmentFrameGroups {
        SegmentFrameGroups(
            frames: frameState.frames,
            groupedFrames: frameState.groupedFrames,
            segmentFrameKeys: frameState.segmentFrameKeys
        )
    }

    var focusedSegmentFrame: CGRect? {
        currentFrameGroups.focusedFrame(for: interactionState.focusedIndex)
    }

    func focusedSegmentFrame(for focusedIndex: Int) -> CGRect? {
        currentFrameGroups.focusedFrame(for: focusedIndex)
    }

    func indicatorFrame(for focusedIndex: Int) -> CGRect? {
        frameState.frames[focusedIndex]
    }

    func effectiveFocusedIndex(in subviews: SubviewsCollection) -> Int {
        if let pendingSelectionIndex = interactionState.pendingSelectionIndex {
            return pendingSelectionIndex
        }

        guard !interactionState.tracksSelectionWhileScrolling else {
            return interactionState.focusedIndex
        }

        guard subviews.indices.contains(interactionState.focusedIndex) else {
            return taggedIndex(for: selection, in: subviews) ?? interactionState.focusedIndex
        }

        return interactionState.focusedIndex
    }

    func segmentGroups(in subviews: SubviewsCollection) -> [SegmentGroup] {
        subviews.indices.reduce(into: []) { groups, index in
            let key = subviews[index].containerValues.dialStylePickerGroupID
                .map(SegmentGroupKey.grouped) ?? .single(index)

            if groups.last?.key == key {
                groups[groups.index(before: groups.endIndex)].indices.append(index)
            } else {
                groups.append(SegmentGroup(key: key, indices: [index]))
            }
        }
    }

    var pickerHeight: CGFloat {
        44
    }

    var pickerContentPadding: CGFloat {
        4
    }

    var strongSnapAnimation: Animation {
        .interpolatingSpring(stiffness: 520, damping: 44)
    }

    var indicatorAnimation: Animation? {
        accessibilityReduceMotion ? nil : .easeInOut(duration: 0.18)
    }

    var coordinateSpaceName: String {
        "DialStylePicker"
    }
}

private struct SegmentLabelModifier: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .bold()
            .foregroundStyle(isFocused ? .yellow : .primary)
            .frame(minWidth: 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }
}

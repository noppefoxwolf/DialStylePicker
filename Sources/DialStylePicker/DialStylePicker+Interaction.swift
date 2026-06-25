import SwiftUI

extension DialStylePicker {
    func updateViewportWidth(_ width: CGFloat) {
        frameState.viewportWidth = width
    }

    func handleAppear(
        viewportWidth: CGFloat,
        subviews: SubviewsCollection
    ) {
        updateViewportWidth(viewportWidth)
        updateFocusedIndex(for: selection, in: subviews)
    }

    func handleViewportWidthChange(
        _ newValue: CGFloat,
        subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) {
        updateViewportWidth(newValue)
        updateFocusedIndex(in: subviews)
        if interactionState.hasScrolledToInitialSelection {
            schedulePendingScrollIfNeeded(scrollView: scrollView)
        } else {
            scrollToInitialSelectionIfNeeded(
                in: subviews,
                scrollView: scrollView
            )
        }
    }

    func schedulePendingScrollIfNeeded(scrollView: ScrollViewProxy) {
        guard let pendingScrollIndex = interactionState.pendingScrollIndex else {
            return
        }

        scheduleScrollToFocusedSelection(pendingScrollIndex, scrollView: scrollView)
    }

    func scheduleScrollToFocusedSelection(scrollView: ScrollViewProxy) {
        scheduleScrollToFocusedSelection(
            interactionState.focusedIndex,
            scrollView: scrollView
        )
    }

    func scheduleScrollToFocusedSelection(
        _ index: Int,
        scrollView: ScrollViewProxy
    ) {
        guard currentFrameGroups.focusedFrame(for: index) != nil else {
            return
        }

        interactionState.pendingScrollIndex = index
        scheduledTasks.scrollTask?.cancel()
        scheduledTasks.scrollTask = Task {
            await Task.yield()
            await Task.yield()

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard
                    interactionState.focusedIndex == index,
                    interactionState.pendingScrollIndex == index
                else {
                    return
                }

                withAnimation(.snappy) {
                    scrollToFocusedSelection(index, scrollView: scrollView)
                }

                interactionState.pendingScrollIndex = nil
            }
        }
    }

    func scrollToFocusedSelection(
        _ index: Int,
        scrollView: ScrollViewProxy
    ) {
        scrollView.scrollTo(
            currentFrameGroups.scrollTarget(for: index),
            anchor: currentFrameGroups.scrollAnchor(for: index)
        )
    }

    func scrollToInitialSelectionIfNeeded(
        frameGroups: SegmentFrameGroups? = nil,
        in subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) {
        guard !interactionState.hasScrolledToInitialSelection else {
            return
        }

        guard frameState.viewportWidth > 0 else {
            return
        }

        updateFocusedIndex(for: selection, in: subviews)

        let frameGroups = frameGroups ?? currentFrameGroups

        guard frameGroups.focusedFrame(for: interactionState.focusedIndex) != nil else {
            return
        }

        scheduledTasks.initialScrollTask?.cancel()
        interactionState.hasScrolledToInitialSelection = true
        scrollView.scrollTo(
            frameGroups.scrollTarget(for: interactionState.focusedIndex),
            anchor: frameGroups.scrollAnchor(for: interactionState.focusedIndex)
        )
        scheduledTasks.initialScrollTask = nil
    }

    func handleSegmentFramesChange(
        _ newValue: [Int: CGRect],
        subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) {
        let frameGroups = SegmentFrameGroups(
            frames: newValue,
            groupContainerFrames: frameState.groupContainerFrames,
            subviews: subviews
        )

        frameState.frames = frameGroups.frames
        frameState.groupedFrames = frameGroups.groupedFrames
        frameState.segmentFrameKeys = frameGroups.segmentFrameKeys
        updateFocusedIndex(
            frameGroups: frameGroups,
            subviews: subviews
        )
        scrollToInitialSelectionIfNeeded(
            frameGroups: frameGroups,
            in: subviews,
            scrollView: scrollView
        )
    }

    func handleSegmentGroupFramesChange(
        _ newValue: [SegmentGroupKey: CGRect],
        subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) {
        let frameGroups = SegmentFrameGroups(
            frames: frameState.frames,
            groupContainerFrames: newValue,
            subviews: subviews
        )

        frameState.groupContainerFrames = newValue
        frameState.groupedFrames = frameGroups.groupedFrames
        frameState.segmentFrameKeys = frameGroups.segmentFrameKeys
        scrollToInitialSelectionIfNeeded(
            frameGroups: frameGroups,
            in: subviews,
            scrollView: scrollView
        )
    }

    func handleScrollPhaseChange(
        from oldPhase: ScrollPhase,
        to newPhase: ScrollPhase,
        subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) {
        if newPhase == .idle {
            interactionState.isScrolling = false
            scheduleCollapse()
            scheduleSelection(in: subviews)
        } else if newPhase == .tracking || newPhase == .interacting {
            scheduledTasks.scrollTask?.cancel()
            scheduledTasks.scrollTask = nil
            scheduledTasks.selectionTask?.cancel()
            scheduledTasks.selectionTask = nil
            interactionState.pendingScrollIndex = nil
            interactionState.pendingSelectionIndex = interactionState.focusedIndex
            interactionState.isScrolling = true
            interactionState.tracksSelectionWhileScrolling = true
            expand()
        } else if newPhase == .decelerating {
            scheduledTasks.scrollTask?.cancel()
            scheduledTasks.scrollTask = nil
            scheduledTasks.selectionTask?.cancel()
            scheduledTasks.selectionTask = nil
            interactionState.pendingScrollIndex = nil
            interactionState.isScrolling = true
            interactionState.tracksSelectionWhileScrolling = true
            snapToCenteredSegment(in: subviews, scrollView: scrollView)
            scheduleCollapse()
        } else {
            scheduledTasks.selectionTask?.cancel()
            scheduledTasks.selectionTask = nil
            interactionState.isScrolling = true
            interactionState.tracksSelectionWhileScrolling = false
            scheduleCollapse()
        }
    }

    func snapToCenteredSegment(
        in subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) {
        guard let centeredItem = centeredSegment(in: currentFrameGroups) else {
            return
        }

        interactionState.pendingSelectionIndex = centeredItem

        if interactionState.focusedIndex != centeredItem {
            interactionState.focusedIndex = centeredItem
            triggerFeedbackIfNeeded(centeredItem, in: subviews)
        }

        withAnimation(strongSnapAnimation) {
            scrollView.scrollTo(
                currentFrameGroups.scrollTarget(for: centeredItem),
                anchor: currentFrameGroups.scrollAnchor(for: centeredItem)
            )
        }
    }

    func handleSelectionChange(
        _ newValue: SelectionValue,
        subviews: SubviewsCollection,
        scrollView: ScrollViewProxy
    ) {
        guard let selectedIndex = taggedIndex(for: newValue, in: subviews) else {
            return
        }

        scheduledTasks.selectionTask?.cancel()
        scheduledTasks.selectionTask = nil
        interactionState.pendingSelectionIndex = nil
        interactionState.tracksSelectionWhileScrolling = false

        withAnimation(.snappy) {
            interactionState.focusedIndex = selectedIndex
        }

        scheduleScrollToFocusedSelection(scrollView: scrollView)
    }

    func updateFocusedIndex(in subviews: SubviewsCollection) {
        updateFocusedIndex(
            frameGroups: currentFrameGroups,
            subviews: subviews
        )
    }

    func updateFocusedIndex(
        frameGroups: SegmentFrameGroups,
        subviews: SubviewsCollection
    ) {
        guard interactionState.tracksSelectionWhileScrolling else {
            return
        }

        guard let centeredItem = centeredSegment(in: frameGroups) else {
            return
        }

        guard interactionState.focusedIndex != centeredItem else {
            return
        }

        withAnimation(.snappy) {
            interactionState.focusedIndex = centeredItem
        }

        interactionState.pendingSelectionIndex = centeredItem

        triggerFeedbackIfNeeded(centeredItem, in: subviews)
    }

    func updateFocusedIndex(
        for selection: SelectionValue,
        in subviews: SubviewsCollection
    ) {
        guard let selectedIndex = taggedIndex(for: selection, in: subviews) else {
            return
        }

        interactionState.focusedIndex = selectedIndex
    }

    func selectCenteredItem(in subviews: SubviewsCollection) {
        let selectionIndex = interactionState.pendingSelectionIndex ?? interactionState.focusedIndex

        guard subviews.indices.contains(selectionIndex) else {
            return
        }

        selectItem(selectionIndex, subview: subviews[selectionIndex])
        interactionState.pendingSelectionIndex = nil
        interactionState.tracksSelectionWhileScrolling = false
    }

    func selectTappedItem(
        _ index: Int,
        subview: Subview,
        scrollView: ScrollViewProxy
    ) {
        guard let tag = subview.containerValues.tag(for: SelectionValue.self) else {
            return
        }

        scheduledTasks.selectionTask?.cancel()
        scheduledTasks.selectionTask = nil
        interactionState.pendingSelectionIndex = nil
        interactionState.tracksSelectionWhileScrolling = false

        withAnimation(.snappy) {
            interactionState.focusedIndex = index
            selection = tag
        }

        scheduleScrollToFocusedSelection(scrollView: scrollView)
    }

    func scheduleSelection(in subviews: SubviewsCollection) {
        scheduledTasks.selectionTask?.cancel()
        scheduledTasks.selectionTask = Task {
            try? await Task.sleep(for: .milliseconds(50))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                selectCenteredItem(in: subviews)
            }
        }
    }

    func triggerFeedbackIfNeeded(
        _ index: Int,
        in subviews: SubviewsCollection
    ) {
        guard interactionState.isScrolling, subviews.indices.contains(index) else {
            return
        }

        guard subviews[index].containerValues.tag(for: SelectionValue.self) != nil else {
            return
        }

        interactionState.feedbackTrigger += 1
    }

    func selectItem(
        _ index: Int,
        subview: Subview
    ) {
        guard let tag = subview.containerValues.tag(for: SelectionValue.self) else {
            return
        }

        withAnimation(.snappy) {
            interactionState.focusedIndex = index
            selection = tag
        }
    }

    func expand() {
        scheduledTasks.collapseTask?.cancel()
        scheduledTasks.collapseTask = nil

        interactionState.showsScrollMask = true

        withAnimation(.snappy) {
            interactionState.isExpanded = true
        }
    }

    func scheduleCollapse() {
        scheduledTasks.collapseTask?.cancel()
        scheduledTasks.collapseTask = Task {
            try? await Task.sleep(for: .milliseconds(140))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    interactionState.showsScrollMask = false
                }

                withAnimation(.snappy) {
                    interactionState.isExpanded = false
                }
            }
        }
    }

    func centeredSegment(in frameGroups: SegmentFrameGroups) -> Int? {
        frameGroups.centeredSegment(nearestTo: frameState.viewportWidth / 2)
    }

    func taggedIndex(
        for selection: SelectionValue,
        in subviews: SubviewsCollection
    ) -> Int? {
        subviews.indices.first { index in
            subviews[index].containerValues.hasTag(selection)
        }
    }
}

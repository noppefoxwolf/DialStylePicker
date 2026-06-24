import SwiftUI

public struct DialStylePicker<SelectionValue: Hashable, Content: View>: View {
    @Binding
    var selection: SelectionValue

    let content: Content

    @State
    var frameState = SegmentFrameState()

    @State
    var interactionState = SegmentInteractionState()

    @State
    var scheduledTasks = SegmentScheduledTasks()

    public init(
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self._selection = selection
        self.content = content()
    }

    public var body: some View {
        Group(subviews: content) { subviews in
            let focusedIndex = effectiveFocusedIndex(in: subviews)
            let pickerWidth = pickerWidth(for: focusedIndex)

            picker(subviews: subviews)
                .frame(width: layoutWidth(for: focusedIndex), height: pickerHeight)
                .mask {
                    pickerMask(width: pickerWidth, focusedIndex: focusedIndex)
                }
                .frame(width: pickerWidth, height: pickerHeight)
                .glassEffect(.clear.interactive())
                .animation(.snappy, value: interactionState.isExpanded)
                .sensoryFeedback(.selection, trigger: interactionState.feedbackTrigger)
        }
    }
}

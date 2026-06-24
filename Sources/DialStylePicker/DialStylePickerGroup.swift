import SwiftUI

public extension View {
    func dialStylePickerGroup<ID: Hashable & Sendable>(_ id: ID) -> some View {
        containerValue(\.dialStylePickerGroupID, DialStylePickerGroupID(id))
    }
}

struct DialStylePickerGroupID: Hashable, @unchecked Sendable {
    private let value: AnyHashable

    init<ID: Hashable & Sendable>(_ value: ID) {
        self.value = AnyHashable(value)
    }
}

struct DialStylePickerGroupIDKey: ContainerValueKey {
    static let defaultValue: DialStylePickerGroupID? = nil
}

extension ContainerValues {
    var dialStylePickerGroupID: DialStylePickerGroupID? {
        get { self[DialStylePickerGroupIDKey.self] }
        set { self[DialStylePickerGroupIDKey.self] = newValue }
    }
}

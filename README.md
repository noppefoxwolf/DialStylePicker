# DialStylePicker

DialStylePicker is a SwiftUI picker that behaves like a compact dial-style segmented control. It centers the selected item, expands while scrolling, supports tagged SwiftUI content, and can group adjacent segments into a shared selection frame.

On iOS 26 and later it uses SwiftUI's glass effect. On earlier supported systems it falls back to a capsule-shaped secondary background.

## Requirements

- iOS 18.0+
- Swift 6.3+
- Xcode with Swift Package Manager support

## Installation

Add this package to your app with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/noppefoxwolf/DialStylePicker.git", from: "0.1.0")
]
```

Then add `DialStylePicker` to your target dependencies.

## Usage

Import the package and bind the picker to a tagged selection value.

```swift
import SwiftUI
import DialStylePicker

struct ContentView: View {
    @State private var selection = "photo"

    var body: some View {
        DialStylePicker(selection: $selection) {
            Text("Video")
                .tag("video")

            Text("Photo")
                .tag("photo")

            Text("Portrait")
                .tag("portrait")
        }
    }
}
```

## Grouped Segments

Use `dialStylePickerGroup(_:)` when multiple adjacent segments should share one background frame while still keeping their own tags.

```swift
DialStylePicker(selection: $selection) {
    Text("Video")
        .tag("video")
        .dialStylePickerGroup("capture")

    Text("Photo")
        .tag("photo")
        .dialStylePickerGroup("capture")

    Text("Portrait")
        .tag("portrait")
}
```

Segments with the same group id are measured as one visual group for the focused background and scroll target.

## Example

An example Swift package is included in `Example.swiftpm`.

```sh
open Example.swiftpm
```

## License

DialStylePicker is available under the MIT license. See [LICENSE](LICENSE) for details.

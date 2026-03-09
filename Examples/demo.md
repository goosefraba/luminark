# Luminark Demo

This viewer is tuned for clean typography, glassy window chrome, and code that still feels readable in both light and dark appearances.

## Features

- Drag a file onto the launcher to open it.
- Use the file picker when no document is loaded.
- Open a second markdown file and compare both windows side by side.

## Code Sample

```swift
struct FeatureFlag {
    let name: String
    let isEnabled: Bool
}

func enabledFlags(from flags: [FeatureFlag]) -> [String] {
    flags
        .filter(\.isEnabled)
        .map(\.name)
}
```

## Table

| Setting | Purpose |
| --- | --- |
| Appearance | Switch between system, light, and dark rendering |
| Transparency | Make the window feel more like frosted glass |

> Markdown should be pleasant to read before it is powerful to inspect.

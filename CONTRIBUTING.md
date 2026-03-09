# Contributing to Luminark

Thanks for contributing.

## Before you start

- Open an issue for larger changes so the direction is clear before implementation.
- Keep changes scoped and focused.
- Prefer native-feeling macOS behavior over cross-platform abstractions.

## Development flow

1. Fork the repository or create a feature branch.
2. Make your change.
3. Run `swift build`.
4. If the change affects rendering or interactions, test the affected flow manually.
5. Open a pull request with a concise description and screenshots for UI changes.

## Pull request expectations

- Explain the user-facing change.
- Call out any tradeoffs or follow-up work.
- Keep PRs small enough to review quickly.

## Code style

- Use SwiftUI and AppKit pragmatically.
- Preserve the app’s visual language.
- Avoid adding dependencies unless they are clearly justified.

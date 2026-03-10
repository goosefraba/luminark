# Changelog

All notable changes to Luminark are documented here.

## [Unreleased]

- No unreleased changes yet.

## [0.1.9] - 2026-03-10

### Fixed

- Fixed Finder and `Open With` markdown launches so the viewer window is brought forward correctly and the launcher no longer remains the apparent result
- Folded pre-launch file-open events into startup routing while still handling post-launch file-open events through the live observer path

## [0.1.8] - 2026-03-10

### Fixed

- Fixed a startup race where Finder `Open With` and double-click launches could arrive before SwiftUI had registered its file-open observer, causing the file to be dropped and only the launcher to appear

## [0.1.7] - 2026-03-10

### Fixed

- Fixed macOS Finder `Open With` and double-click launches so markdown files assigned to Luminark open directly instead of showing only the launcher drop zone on cold start

## [0.1.6] - 2026-03-10

### Fixed

- Made the launcher drop-state window respect the active light/dark appearance instead of always rendering a light-toned panel

## [0.1.5] - 2026-03-10

### Added

- Shipped the new dark metallic cyan `LM` app icon through the packaged macOS app bundle

### Fixed

- Brought the launcher window back to the front when the last viewer window closes
- Compiled the app icon asset catalog into packaged release builds so macOS picks up `AppIcon` correctly

## [0.1.4] - 2026-03-10

### Fixed

- Repaired packaged app bundle layout so release builds use a standard `Contents/Resources` resource location
- Re-signed packaged release apps after bundling so the shipped `.app` is structurally valid on disk
- Cleaned release zip output to avoid extra macOS metadata files

### Changed

- Added installation notes for the current unsigned, non-notarized release flow

## [0.1.3] - 2026-03-10

### Changed

- Added explicit release download guidance to the README, including architecture notes and a direct link to the GitHub Releases page

## [0.1.2] - 2026-03-10

### Added

- Finder/open-file handling so packaged app releases can receive markdown files from `Open With` and default-app launches
- Packaged markdown document type declarations for `.md`, `.markdown`, `.mdown`, `.mkd`, and `.mkdn`
- Release packaging and publishing scripts

### Changed

- Standardized release notes into markdown files and scripts so future GitHub release pages render correctly

## [0.1.1] - 2026-03-10

### Added

- In-app update availability checking against GitHub Releases
- Native `Check for Updates…` command
- Automatic update-check preference in Settings

### Changed

- Simplified updates to a release-page flow for manual downloads

## [0.1.0] - 2026-03-09

### Added

- First public release of Luminark
- Native macOS markdown viewing with polished rendering
- Light and dark themes
- Adjustable transparency and reading size
- Drag and drop from Finder directly onto the rendered document
- Smooth in-page anchor navigation and scroll-to-top control

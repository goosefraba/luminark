# Changelog

All notable changes to Luminark are documented here.

## [Unreleased]

- No unreleased changes yet.

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

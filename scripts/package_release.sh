#!/bin/zsh
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <version>" >&2
  exit 1
fi

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release-artifacts/$VERSION"
APP_NAME="Luminark"
IDENTIFIER="com.goosefraba.luminark"
ASSET_CATALOG="$ROOT_DIR/Sources/LuminarkApp/Resources/Assets.xcassets"

mkdir -p "$RELEASE_DIR"

for ARCH in arm64 x86_64; do
  swift build -c release --arch "$ARCH" --package-path "$ROOT_DIR"

  STAGING_DIR="$RELEASE_DIR/staging-${ARCH}"
  APP_DIR="$STAGING_DIR/${APP_NAME}.app"
  ASSET_INFO_PLIST="$(mktemp "$RELEASE_DIR/${APP_NAME}-${ARCH}-asset-info.XXXXXX.plist")"
  rm -rf "$STAGING_DIR"
  mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

  cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeExtensions</key>
      <array>
        <string>md</string>
        <string>markdown</string>
        <string>mdown</string>
        <string>mkd</string>
        <string>mkdn</string>
      </array>
      <key>CFBundleTypeIconSystemGenerated</key>
      <true/>
      <key>CFBundleTypeName</key>
      <string>Markdown Document</string>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSHandlerRank</key>
      <string>Default</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>net.daringfireball.markdown</string>
      </array>
    </dict>
  </array>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$IDENTIFIER</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>15.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright 2026 goosefraba</string>
  <key>UTImportedTypeDeclarations</key>
  <array>
    <dict>
      <key>UTTypeConformsTo</key>
      <array>
        <string>public.plain-text</string>
      </array>
      <key>UTTypeDescription</key>
      <string>Markdown document</string>
      <key>UTTypeIdentifier</key>
      <string>net.daringfireball.markdown</string>
      <key>UTTypeTagSpecification</key>
      <dict>
        <key>public.filename-extension</key>
        <array>
          <string>md</string>
          <string>markdown</string>
          <string>mdown</string>
          <string>mkd</string>
          <string>mkdn</string>
        </array>
        <key>public.mime-type</key>
        <array>
          <string>text/markdown</string>
          <string>text/x-markdown</string>
        </array>
      </dict>
    </dict>
  </array>
</dict>
</plist>
PLIST

  cp "$ROOT_DIR/.build/${ARCH}-apple-macosx/release/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
  cp -R \
    "$ROOT_DIR/.build/${ARCH}-apple-macosx/release/${APP_NAME}_LuminarkApp.bundle" \
    "$APP_DIR/Contents/Resources/${APP_NAME}_LuminarkApp.bundle"
  xcrun actool \
    --compile "$APP_DIR/Contents/Resources" \
    --platform macosx \
    --minimum-deployment-target 15.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$ASSET_INFO_PLIST" \
    "$ASSET_CATALOG" >/dev/null
  rm -f "$ASSET_INFO_PLIST"
  chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
  xattr -cr "$APP_DIR"
  codesign --force --deep --sign - --timestamp=none "$APP_DIR"
  xattr -dr com.apple.provenance "$APP_DIR" 2>/dev/null || true

  ditto -c -k --norsrc --keepParent "$APP_DIR" "$RELEASE_DIR/${APP_NAME}-${VERSION}-macos-${ARCH}.zip"
done

ls -lh "$RELEASE_DIR"/*.zip

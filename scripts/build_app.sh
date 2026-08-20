#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "🔨 [1/4] 正在编译 Paster (Release 模式)..."
swift build -c release

APP_NAME="Paster"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 [2/4] 构建应用目录结构..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 复制二进制可执行文件
cp "$PROJECT_DIR/.build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# 复制 Info.plist 与资源
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/Resources/glue_stick"* "$RESOURCES_DIR/"

echo "🎨 [3/4] 生成高清应用图标..."
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"
swift scripts/generate_icon.swift "$BUILD_DIR/icon_512.png"

# 生成各尺寸 iconset
sips -z 16 16     "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
sips -z 32 32     "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
sips -z 32 32     "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
sips -z 64 64     "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
sips -z 128 128   "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
sips -z 256 256   "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
sips -z 256 256   "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
sips -z 512 512   "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
sips -z 512 512   "$BUILD_DIR/icon_512.png" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1

iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET_DIR" "$BUILD_DIR/icon_512.png"

echo "✨ [4/4] 签名应用 (Ad-hoc 本地签名)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "🎉 构建完成！应用位置:"
echo "👉 $APP_BUNDLE"
echo ""
echo "可直接在终端中运行: open \"$APP_BUNDLE\""

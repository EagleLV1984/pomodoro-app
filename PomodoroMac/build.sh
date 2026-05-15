#!/bin/bash
# 超坦番茄钟 Mac 版构建脚本
set -e

APP_NAME="Pomodoro"
BUILD_DIR="./build"
RELEASE_DIR="./release"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "=== 清理 ==="
rm -rf "${BUILD_DIR}" "${RELEASE_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${RELEASE_DIR}"

echo "=== 编译 Swift ==="
swiftc -O \
    -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" \
    main.swift \
    -framework Cocoa \
    -framework WebKit \
    -framework SwiftUI \
    -sdk $(xcrun --show-sdk-path) \
    -target arm64-apple-macos14.0

echo "=== 复制资源 ==="
cp pomodoro.html "${APP_BUNDLE}/Contents/Resources/"
cp pomodoro.png "${APP_BUNDLE}/Contents/Resources/" 2>/dev/null || echo "(pomodoro.png 未找到，使用默认)"

echo "=== 生成图标 ==="
if [ -f "AppIcon.png" ]; then
  ICONSET="${BUILD_DIR}/AppIcon.iconset"
  mkdir -p "${ICONSET}"
  sips -z 16 16   AppIcon.png --out "${ICONSET}/icon_16x16.png" 2>/dev/null
  sips -z 32 32   AppIcon.png --out "${ICONSET}/icon_16x16@2x.png" 2>/dev/null
  sips -z 32 32   AppIcon.png --out "${ICONSET}/icon_32x32.png" 2>/dev/null
  sips -z 64 64   AppIcon.png --out "${ICONSET}/icon_32x32@2x.png" 2>/dev/null
  sips -z 128 128 AppIcon.png --out "${ICONSET}/icon_128x128.png" 2>/dev/null
  sips -z 256 256 AppIcon.png --out "${ICONSET}/icon_128x128@2x.png" 2>/dev/null
  sips -z 256 256 AppIcon.png --out "${ICONSET}/icon_256x256.png" 2>/dev/null
  sips -z 512 512 AppIcon.png --out "${ICONSET}/icon_256x256@2x.png" 2>/dev/null
  sips -z 512 512 AppIcon.png --out "${ICONSET}/icon_512x512.png" 2>/dev/null
  sips -z 1024 1024 AppIcon.png --out "${ICONSET}/icon_512x512@2x.png" 2>/dev/null
  iconutil -c icns "${ICONSET}" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
  rm -rf "${ICONSET}"
  echo "图标已生成"
else
  echo "(AppIcon.png 未找到，跳过图标)"
fi

echo "=== Info.plist ==="
cat > "${APP_BUNDLE}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>超坦番茄钟</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.pomodoro.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Pomodoro</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>超坦番茄钟使用音频提示</string>
</dict>
</plist>
PLIST

echo "=== Ad-Hoc 签名 ==="
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "=== 创建 DMG ==="
DMG_FILE="${RELEASE_DIR}/Pomodoro.dmg"
DMG_TEMP="${BUILD_DIR}/dmg_temp"
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"
cp -R "${APP_BUNDLE}" "${DMG_TEMP}/"
# 创建 Applications 快捷方式
ln -s /Applications "${DMG_TEMP}/Applications"

hdiutil create -volname "超坦番茄钟" -srcfolder "${DMG_TEMP}" -ov -format UDZO "${DMG_FILE}" 2>&1 | tail -1
hdiutil internet-enable -yes "${DMG_FILE}" 2>/dev/null || true
echo "DMG: ${DMG_FILE}"

echo "=== 创建 ZIP ==="
ZIP_FILE="${RELEASE_DIR}/PomodoroMac.zip"
ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_FILE}"
echo "ZIP: ${ZIP_FILE}"

echo "=== 创建一键启动脚本 ==="
cat > "${RELEASE_DIR}/启动超坦番茄钟.command" << 'LAUNCHER'
#!/bin/bash
# 双击此文件即可运行超坦番茄钟（无需手动解除隔离）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="${SCRIPT_DIR}/Pomodoro.app"

# 自动解除隔离
if [ -e "${APP}" ]; then
    xattr -cr "${APP}" 2>/dev/null
    if $(xattr -p com.apple.quarantine "${APP}" 2>/dev/null); then
        echo "正在解除安全限制（需输入密码）..."
        sudo xattr -cr "${APP}" 2>/dev/null || true
    fi
    echo "启动超坦番茄钟..."
    open "${APP}"
else
    echo "错误: 找不到 Pomodoro.app"
    echo "请确保此脚本和 Pomodoro.app 在同一文件夹内"
    read -p "按回车退出..."
fi
LAUNCHER
chmod +x "${RELEASE_DIR}/启动超坦番茄钟.command"

echo ""
echo "========== 构建完成 =========="
echo "输出目录: ${RELEASE_DIR}/"
echo ""
echo "分发方式 (二选一):"
echo ""
echo "  [推荐] DMG: ${DMG_FILE}"
echo "  → 对方打开 DMG，拖到 Applications 即可"
echo "  → 首次右键 '打开' 或在 系统设置→隐私 中允许"
echo ""
echo "  ZIP + 启动器:"
echo "  → 将 ZIP 和 启动超坦番茄钟.command 一起发送"
echo "  → 解压 ZIP，双击 .command 文件即可（自动解除隔离）"
echo ""
echo "  或者用 AirDrop 发送 .app 本身(通常不带隔离)"

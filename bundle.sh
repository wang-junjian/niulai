#!/bin/bash
# 把 SwiftPM 编译出的二进制打包成 Niulai.app（ad-hoc 签名，本机可运行）。
# 打包后 LSUIElement 生效（无 Dock 图标），也可在 系统设置 > 登录项 中加入开机自启。
set -e
cd "$(dirname "$0")"

APP=Niulai.app

echo "🔨 编译 release 版本..."
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Niulai "$APP/Contents/MacOS/"

# 音效资源（SwiftPM 生成的资源 bundle：mama.mp3 / niulai.mp3）
cp -R .build/release/Niulai_Niulai.bundle "$APP/Contents/Resources/" 2>/dev/null || true

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>牛来</string>
    <key>CFBundleIdentifier</key>
    <string>com.niulai.desktoppet</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>CFBundleExecutable</key>
    <string>Niulai</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

codesign --force --sign - "$APP" 2>/dev/null || true

echo "✅ 打包完成：$(pwd)/$APP"
echo "   双击即可运行；如需开机自启：系统设置 → 通用 → 登录项 → 添加 Niulai.app"

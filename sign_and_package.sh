#!/bin/bash

# MonkeyBrowser 签名和打包脚本
# 用于越狱设备的 IPA 打包

set -e

APP_NAME="MonkeyBrowser"
BUILD_DIR="build"
IPA_DIR="ipa"
EXPORT_OPTIONS="exportOptions.plist"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  MonkeyBrowser IPA Packager${NC}"
echo -e "${GREEN}========================================${NC}"

# 创建 exportOptions.plist
cat > "$EXPORT_OPTIONS" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>enterprise</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

echo -e "${YELLOW}[1/4] 构建项目...${NC}"
./build.sh

echo -e "${YELLOW}[2/4] 查找 .app 文件...${NC}"
APP_PATH=$(find "$BUILD_DIR" -name "${APP_NAME}.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    # 尝试从 DerivedData 查找
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" -type d 2>/dev/null | head -1)
fi

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}错误: 未找到 .app 文件${NC}"
    echo -e "${YELLOW}请确保已安装 Xcode 并配置好开发者证书${NC}"
    exit 1
fi

echo -e "${GREEN}找到应用: $APP_PATH${NC}"

echo -e "${YELLOW}[3/4] 签名应用...${NC}"

# 获取签名身份
SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "iPhone" | head -1 | awk -F '"' '{print $2}')

if [ -z "$SIGNING_IDENTITY" ]; then
    echo -e "${RED}未找到签名身份，尝试使用 ad-hoc 签名...${NC}"
    codesign --force --sign - "$APP_PATH"
else
    echo -e "${GREEN}使用签名: $SIGNING_IDENTITY${NC}"
    codesign --force --sign "$SIGNING_IDENTITY" "$APP_PATH"
fi

echo -e "${YELLOW}[4/4] 打包 IPA...${NC}"
rm -rf "$IPA_DIR"
mkdir -p "$IPA_DIR/Payload"
cp -R "$APP_PATH" "$IPA_DIR/Payload/"

cd "$IPA_DIR"
zip -r "../${APP_NAME}_signed.ipa" Payload/
cd ..

# 清理
rm -rf "$EXPORT_OPTIONS"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  打包完成!${NC}"
echo -e "${GREEN}  IPA 文件: ${APP_NAME}_signed.ipa${NC}"
echo -e "${GREEN}========================================${NC}"

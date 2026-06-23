#!/bin/bash

# MonkeyBrowser 快速构建脚本 (无需签名)
# 用于越狱设备直接安装

set -e

APP_NAME="MonkeyBrowser"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  MonkeyBrowser IPA Builder (No Sign)${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}错误: 未找到 xcodebuild，请安装 Xcode${NC}"
    exit 1
fi

# 清理
echo -e "${YELLOW}[1/5] 清理...${NC}"
rm -rf build ipa ${APP_NAME}.ipa

# 构建
echo -e "${YELLOW}[2/5] 构建项目...${NC}"

# 检测 workspace 或 project
if [ -d "${APP_NAME}.xcworkspace" ]; then
    BUILD_INPUT="${APP_NAME}.xcworkspace"
else
    BUILD_INPUT="${APP_NAME}.xcodeproj"
fi

xcodebuild clean build \
    -project "$BUILD_INPUT" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath build \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty || true

# 查找 .app
echo -e "${YELLOW}[3/5] 查找构建产物...${NC}"
APP_PATH=$(find build -name "${APP_NAME}.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}错误: 构建失败${NC}"
    exit 1
fi

# 创建 Payload
echo -e "${YELLOW}[4/5] 创建 IPA...${NC}"
mkdir -p ipa/Payload
cp -R "$APP_PATH" ipa/Payload/

cd ipa
zip -r "../${APP_NAME}.ipa" Payload/
cd ..

# 清理
echo -e "${YELLOW}[5/5] 清理...${NC}"
rm -rf build ipa

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  完成! IPA: ${APP_NAME}.ipa${NC}"
echo -e "${GREEN}========================================${NC}"

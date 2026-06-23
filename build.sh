#!/bin/bash

# MonkeyBrowser 构建脚本
# 用于在 Mac 上构建 IPA 文件

set -e

# 配置
PROJECT_NAME="MonkeyBrowser"
SCHEME="MonkeyBrowser"
CONFIGURATION="Release"
BUILD_DIR="build"
IPA_DIR="ipa"
TEAM_ID="${TEAM_ID:-YOUR_TEAM_ID}"
BUNDLE_ID="com.monkeybrowser.app"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  MonkeyBrowser IPA Builder${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}错误: 未找到 xcodebuild，请安装 Xcode${NC}"
    exit 1
fi

# 清理旧构建
echo -e "${YELLOW}[1/6] 清理旧构建...${NC}"
rm -rf "$BUILD_DIR" "$IPA_DIR"
mkdir -p "$BUILD_DIR" "$IPA_DIR"

# 安装 CocoaPods（如果需要）
if [ -f "Podfile" ] && ! command -v pod &> /dev/null; then
    echo -e "${YELLOW}[2/6] 安装 CocoaPods...${NC}"
    sudo gem install cocoapods
    pod install
elif [ -f "Podfile" ]; then
    echo -e "${YELLOW}[2/6] 更新 Pods...${NC}"
    pod install
fi

# 构建项目
echo -e "${YELLOW}[3/6] 构建项目...${NC}"

# 检测 workspace 或 project
if [ -d "${PROJECT_NAME}.xcworkspace" ]; then
    BUILD_INPUT="${PROJECT_NAME}.xcworkspace"
else
    BUILD_INPUT="${PROJECT_NAME}.xcodeproj"
fi

xcodebuild clean build \
    -project "$BUILD_INPUT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -destination "generic/platform=iOS" \
    -allowProvisioningUpdates \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    MARKETING_VERSION="1.0.0" \
    CURRENT_PROJECT_VERSION="1" \
    | xcpretty

# 创建 IPA 结构
echo -e "${YELLOW}[4/6] 创建 IPA 结构...${NC}"

# 查找 .app 文件
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "${PROJECT_NAME}.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}错误: 未找到构建的 .app 文件${NC}"
    exit 1
fi

echo -e "${GREEN}找到应用: $APP_PATH${NC}"

# 创建 Payload 目录
mkdir -p "$IPA_DIR/Payload"
cp -R "$APP_PATH" "$IPA_DIR/Payload/"

# 创建 IPA
echo -e "${YELLOW}[5/6] 打包 IPA...${NC}"
cd "$IPA_DIR"
zip -r "../${PROJECT_NAME}.ipa" Payload/
cd ..

# 清理
echo -e "${YELLOW}[6/6] 清理临时文件...${NC}"
rm -rf "$BUILD_DIR"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  构建完成!${NC}"
echo -e "${GREEN}  IPA 文件: ${PROJECT_NAME}.ipa${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}安装方法:${NC}"
echo "1. 使用 AltStore 安装"
echo "2. 使用 Sileo/Cydia 安装 (越狱设备)"
echo "3. 使用 impactor 安装"
echo ""

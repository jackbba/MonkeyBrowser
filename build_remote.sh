#!/bin/bash
# MonkeyBrowser GitHub Actions 构建助手 (Linux/Mac)

set -e

echo "=========================================="
echo "  MonkeyBrowser IPA Builder"
echo "=========================================="
echo ""

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查 gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}错误: 未找到 GitHub CLI${NC}"
    echo ""
    echo "安装方法:"
    echo "  Mac: brew install gh"
    echo "  Linux: sudo apt install gh"
    echo "  Windows: winget install GitHub.cli"
    echo ""
    echo "或者手动操作:"
    echo "1. 访问 https://github.com/YOUR_USERNAME/MonkeyBrowser/actions"
    echo "2. 点击 'Build IPA'"
    echo "3. 等待构建完成"
    echo "4. 下载 Artifact 中的 IPA"
    exit 1
fi

# 登录检查
echo -e "${YELLOW}[1/4] 检查 GitHub 登录状态...${NC}"
if ! gh auth status &> /dev/null; then
    echo "请先登录 GitHub:"
    gh auth login
fi

# 初始化 Git 仓库（如果还没有）
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}[2/4] 初始化 Git 仓库...${NC}"
    git init
    git add .
    git commit -m "Initial commit: MonkeyBrowser"
    
    echo ""
    echo -e "${YELLOW}请输入你的 GitHub 仓库 URL:${NC}"
    echo "例如: https://github.com/username/MonkeyBrowser.git"
    read REPO_URL
    
    git remote add origin "$REPO_URL"
    git push -u origin main
else
    echo -e "${GREEN}[2/4] Git 仓库已存在${NC}"
    git add .
    git commit -m "Update: $(date +%Y-%m-%d)" || true
    git push
fi

# 触发构建
echo -e "${YELLOW}[3/4] 触发 GitHub Actions 构建...${NC}"
gh workflow run build.yml

echo -e "${YELLOW}[4/4] 等待构建完成...${NC}"
echo "构建通常需要 5-10 分钟"
echo ""

# 等待并下载
while true; do
    sleep 10
    RUN_STATUS=$(gh run list --workflow=build.yml --limit=1 --json status --jq '.[0].status')
    
    if [ "$RUN_STATUS" = "completed" ]; then
        echo -e "${GREEN}构建完成!${NC}"
        break
    elif [ "$RUN_STATUS" = "in_progress" ]; then
        echo -n "."
    else
        echo -e "${YELLOW}等待中...${NC}"
    fi
done

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  下载 IPA 文件...${NC}"
echo -e "${GREEN}=========================================${NC}"

gh run download --name MonkeyBrowser

echo ""
echo -e "${GREEN}IPA 已下载到当前目录!${NC}"
echo ""

# 列出文件
ls -la *.ipa 2>/dev/null || echo "IPA 文件: MonkeyBrowser.ipa"

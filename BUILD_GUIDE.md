# MonkeyBrowser - IPA 构建指南

## 在 Windows 上构建 IPA

由于 iOS 编译需要 macOS 环境，我们使用 **GitHub Actions** 在云端免费构建 IPA。

---

## 方法一：GitHub Actions 自动构建（推荐）

### 步骤 1: 安装 GitHub CLI

```powershell
# 使用 winget 安装
winget install GitHub.cli

# 或者从官网下载
# https://cli.github.com/
```

### 步骤 2: 登录 GitHub

```powershell
gh auth login
```

### 步骤 3: 创建 GitHub 仓库

1. 访问 https://github.com/new
2. 仓库名: `MonkeyBrowser`
3. 选择 **Public** 或 **Private**
4. 点击 **Create repository**
5. 复制仓库 URL (例如: `https://github.com/你的用户名/MonkeyBrowser.git`)

### 步骤 4: 上传代码并构建

```powershell
cd E:\1\MonkeyBrowser

# 初始化 Git
git init
git add .
git commit -m "Initial commit"

# 连接远程仓库 (替换为你的URL)
git remote add origin https://github.com/你的用户名/MonkeyBrowser.git
git push -u origin main

# 触发自动构建
gh workflow run build.yml
```

### 步骤 5: 下载 IPA

```powershell
# 查看构建状态
gh run list --workflow=build.yml

# 下载 IPA
gh run download --name MonkeyBrowser
```

或者访问: `https://github.com/你的用户名/MonkeyBrowser/actions`

---

## 方法二：使用构建脚本

### 快速构建（无签名）

```bash
chmod +x build_no_sign.sh
./build_no_sign.sh
```

### 签名构建

```bash
chmod +x sign_and_package.sh
./sign_and_package.sh
```

---

## 方法三：在 Mac 上本地构建

如果你有 Mac：

```bash
# 1. 复制项目到 Mac
scp -r E:\1\MonkeyBrowser user@mac:~/Desktop/

# 2. 在 Mac 上
cd ~/Desktop/MonkeyBrowser
chmod +x build.sh
./build.sh
```

---

## 安装 IPA 到越狱设备

### 使用 Sileo/Cydia

1. 下载 IPA 文件
2. 使用 Filza 文件管理器
3. 导航到 IPA 文件位置
4. 点击安装

### 使用 TrollStore (推荐)

```bash
# 如果已安装 TrollStore
# 直接通过 URL 或文件安装 IPA
```

### 使用 AltStore

1. 在电脑安装 AltServer
2. 连接 iPhone
3. 将 IPA 拖入 AltStore

---

## 项目文件说明

```
MonkeyBrowser/
├── .github/workflows/      # GitHub Actions 配置
│   ├── build.yml           # 无签名构建
│   └── build-signed.yml    # 签名构建
├── build.sh                # Mac 构建脚本
├── build_no_sign.sh        # 无签名构建脚本
├── sign_and_package.sh     # 签名打包脚本
├── download_ipa.bat        # Windows 下载脚本
└── build_remote.sh         # 远程构建脚本
```

---

## 常见问题

### Q: 构建失败怎么办？

A: 检查 GitHub Actions 日志:
```powershell
gh run view --log
```

### Q: 如何添加 VLC 依赖？

A: 在 Mac 上运行:
```bash
pod install
```

然后重新提交代码。

### Q: 需要 Apple 开发者账号吗？

A: 不需要！越狱设备可以直接安装未签名的 IPA。

---

## 自动构建脚本

运行以下命令自动完成所有步骤:

```powershell
# Windows
download_ipa.bat

# 或者在 Git Bash 中
bash build_remote.sh
```

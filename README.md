# MonkeyBrowser - 油猴脚本浏览器

支持油猴脚本和VLC内核的原生iOS浏览器，最低支持iOS 15.0。

## 功能特性

### 核心功能
- **WKWebView 浏览器引擎** - 完整的网页浏览体验
- **油猴脚本支持** - 加载和执行Tampermonkey/Greasemonkey脚本
- **VLC视频播放** - 支持多种视频格式的原生播放
- **字幕支持** - SRT/ASS/SSA/VTT格式字幕加载

### 浏览器功能
- 多标签页管理
- 书签系统
- 前进/后退/刷新
- URL栏支持搜索和网址输入
- 页面加载进度条
- 桌面模式切换

### 脚本引擎
- 解析油猴脚本元数据（@name, @match, @run-at等）
- 支持脚本安装/卸载/启用/禁用
- 从剪贴板或URL导入脚本
- 按URL模式匹配脚本

### 视频播放器
- 基于MobileVLCKit的视频播放
- 支持多种视频格式（MP4, MKV, AVI等）
- 播放控制（播放/暂停/进度条）
- 内置字幕支持
- 外部字幕文件加载

## 项目结构

```
MonkeyBrowser/
├── MonkeyBrowser.xcodeproj/
├── Package.swift
├── Podfile
└── MonkeyBrowser/
    ├── Sources/
    │   ├── App/
    │   │   ├── AppDelegate.swift
    │   │   ├── SceneDelegate.swift
    │   │   └── MainTabBarController.swift
    │   ├── Browser/
    │   │   ├── BrowserViewController.swift
    │   │   └── TabsViewController.swift
    │   ├── ScriptEngine/
    │   │   ├── UserScriptEngine.swift
    │   │   └── ScriptImporter.swift
    │   ├── VideoPlayer/
    │   │   └── VLCPlayerViewController.swift
    │   ├── Subtitle/
    │   │   └── SubtitleManager.swift
    │   ├── Settings/
    │   │   ├── ScriptsViewController.swift
    │   │   ├── BookmarksViewController.swift
    │   │   └── SettingsViewController.swift
    │   ├── Models/
    │   │   └── DataModels.swift
    │   └── Extensions/
    │       └── Extensions.swift
    ├── Resources/
    │   └── Assets.xcassets/
    └── Supporting Files/
        └── Info.plist
```

## 安装和运行

### 方式1: 使用CocoaPods

```bash
cd MonkeyBrowser
pod install
open MonkeyBrowser.xcworkspace
```

### 方式2: 使用Swift Package Manager

```bash
cd MonkeyBrowser
swift package resolve
open Package.swift
```

### 方式3: 使用XcodeGen

```bash
cd MonkeyBrowser
xcodegen generate
open MonkeyBrowser.xcodeproj
```

## 配置说明

### VLC内核配置

1. 下载MobileVLCKit框架
2. 添加到项目的Frameworks中
3. 确保在Build Settings中设置正确的路径

### 油猴脚本安装

1. 打开脚本标签页
2. 点击 + 按钮
3. 选择"从剪贴板导入"或"从URL导入"
4. 脚本会自动解析并启用

### 字幕使用

1. 在VLC播放器中点击字幕按钮
2. 选择"加载外部字幕文件"
3. 支持SRT, ASS, SSA, VTT格式

## 系统要求

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 依赖项

- MobileVLCKit 3.5.0+
- Alamofire 5.8+ (可选)
- SwiftyJSON 5.0+ (可选)
- Kingfisher 7.10+ (可选)

## 许可证

MIT License

#!/bin/bash

# Windows 环境准备脚本
# 帮助在 Windows 上准备 iOS 构建环境

set -e

echo "========================================="
echo "  MonkeyBrowser Windows 环境准备"
echo "========================================="

# 检查 Git
if ! command -v git &> /dev/null; then
    echo "请安装 Git: https://git-scm.com/download/win"
    exit 1
fi

# 检查 Python
if ! command -v python &> /dev/null; then
    echo "请安装 Python: https://www.python.org/downloads/"
    exit 1
fi

# 创建 Xcode 项目模板
echo "[1/3] 创建 Xcode 项目文件..."

# 生成 pbxproj 文件
cat > MonkeyBrowser.xcodeproj/project.pbxproj << 'PBXEOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		A10001 /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20001 /* AppDelegate.swift */; };
		A10002 /* SceneDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20002 /* SceneDelegate.swift */; };
		A10003 /* MainTabBarController.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20003 /* MainTabBarController.swift */; };
		A10004 /* BrowserViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20004 /* BrowserViewController.swift */; };
		A10005 /* TabsViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20005 /* TabsViewController.swift */; };
		A10006 /* UserScriptEngine.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20006 /* UserScriptEngine.swift */; };
		A10007 /* ScriptImporter.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20007 /* ScriptImporter.swift */; };
		A10008 /* VLCPlayerViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20008 /* VLCPlayerViewController.swift */; };
		A10009 /* PiPManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20009 /* PiPManager.swift */; };
		A10010 /* FloatingPlayerManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20010 /* FloatingPlayerManager.swift */; };
		A10011 /* SubtitleManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20011 /* SubtitleManager.swift */; };
		A10012 /* ScriptsViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20012 /* ScriptsViewController.swift */; };
		A10013 /* BookmarksViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20013 /* BookmarksViewController.swift */; };
		A10014 /* SettingsViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20014 /* SettingsViewController.swift */; };
		A10015 /* DataModels.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20015 /* DataModels.swift */; };
		A10016 /* Extensions.swift in Sources */ = {isa = PBXBuildFile; fileRef = A20016 /* Extensions.swift */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		A20001 /* AppDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = "<group>"; };
		A20002 /* SceneDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SceneDelegate.swift; sourceTree = "<group>"; };
		A20003 /* MainTabBarController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MainTabBarController.swift; sourceTree = "<group>"; };
		A20004 /* BrowserViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BrowserViewController.swift; sourceTree = "<group>"; };
		A20005 /* TabsViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TabsViewController.swift; sourceTree = "<group>"; };
		A20006 /* UserScriptEngine.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = UserScriptEngine.swift; sourceTree = "<group>"; };
		A20007 /* ScriptImporter.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ScriptImporter.swift; sourceTree = "<group>"; };
		A20008 /* VLCPlayerViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = VLCPlayerViewController.swift; sourceTree = "<group>"; };
		A20009 /* PiPManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PiPManager.swift; sourceTree = "<group>"; };
		A20010 /* FloatingPlayerManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FloatingPlayerManager.swift; sourceTree = "<group>"; };
		A20011 /* SubtitleManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SubtitleManager.swift; sourceTree = "<group>"; };
		A20012 /* ScriptsViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ScriptsViewController.swift; sourceTree = "<group>"; };
		A20013 /* BookmarksViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BookmarksViewController.swift; sourceTree = "<group>"; };
		A20014 /* SettingsViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SettingsViewController.swift; sourceTree = "<group>"; };
		A20015 /* DataModels.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DataModels.swift; sourceTree = "<group>"; };
		A20016 /* Extensions.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Extensions.swift; sourceTree = "<group>"; };
		A20017 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		A20018 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		A20019 /* MonkeyBrowser.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MonkeyBrowser.app; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		A30001 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		A40001 = {
			isa = PBXGroup;
			children = (
				A40002 /* MonkeyBrowser */,
				A40009 /* Products */,
			);
			sourceTree = "<group>";
		};
		A40002 /* MonkeyBrowser */ = {
			isa = PBXGroup;
			children = (
				A40003 /* Sources */,
				A40008 /* Resources */,
			);
			path = MonkeyBrowser;
			sourceTree = "<group>";
		};
		A40003 /* Sources */ = {
			isa = PBXGroup;
			children = (
				A40004 /* App */,
				A40005 /* Browser */,
				A40006 /* ScriptEngine */,
				A40007 /* VideoPlayer */,
			);
			path = Sources;
			sourceTree = "<group>";
		};
		A40004 /* App */ = {
			isa = PBXGroup;
			children = (
				A20001 /* AppDelegate.swift */,
				A20002 /* SceneDelegate.swift */,
				A20003 /* MainTabBarController.swift */,
			);
			path = App;
			sourceTree = "<group>";
		};
		A40005 /* Browser */ = {
			isa = PBXGroup;
			children = (
				A20004 /* BrowserViewController.swift */,
				A20005 /* TabsViewController.swift */,
			);
			path = Browser;
			sourceTree = "<group>";
		};
		A40006 /* ScriptEngine */ = {
			isa = PBXGroup;
			children = (
				A20006 /* UserScriptEngine.swift */,
				A20007 /* ScriptImporter.swift */,
			);
			path = ScriptEngine;
			sourceTree = "<group>";
		};
		A40007 /* VideoPlayer */ = {
			isa = PBXGroup;
			children = (
				A20008 /* VLCPlayerViewController.swift */,
				A20009 /* PiPManager.swift */,
				A20010 /* FloatingPlayerManager.swift */,
				A20011 /* SubtitleManager.swift */,
				A20012 /* ScriptsViewController.swift */,
				A20013 /* BookmarksViewController.swift */,
				A20014 /* SettingsViewController.swift */,
				A20015 /* DataModels.swift */,
				A20016 /* Extensions.swift */,
			);
			path = Sources;
			sourceTree = "<group>";
		};
		A40008 /* Resources */ = {
			isa = PBXGroup;
			children = (
				A20017 /* Assets.xcassets */,
				A20018 /* Info.plist */,
			);
			path = Resources;
			sourceTree = "<group>";
		};
		A40009 /* Products */ = {
			isa = PBXGroup;
			children = (
				A20019 /* MonkeyBrowser.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		A50001 /* MonkeyBrowser */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = A70001 /* Build configuration list for PBXNativeTarget "MonkeyBrowser" */;
			buildPhases = (
				A30002 /* Sources */,
				A30001 /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = MonkeyBrowser;
			productName = MonkeyBrowser;
			productReference = A20019 /* MonkeyBrowser.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		A60001 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastUpgradeCheck = 1400;
				TargetAttributes = {
					A50001 = {
						CreatedOnToolsVersion = 14.0;
					};
				};
			};
			buildConfigurationList = A70003 /* Build configuration list for PBXProject "MonkeyBrowser" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
				"zh-Hans",
			);
			mainGroup = A40001;
			productRefGroup = A40009 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				A50001 /* MonkeyBrowser */,
			);
		};
/* End PBXProject section */

/* Begin PBXSourcesBuildPhase section */
		A30002 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A10001 /* AppDelegate.swift */,
				A10002 /* SceneDelegate.swift */,
				A10003 /* MainTabBarController.swift */,
				A10004 /* BrowserViewController.swift */,
				A10005 /* TabsViewController.swift */,
				A10006 /* UserScriptEngine.swift */,
				A10007 /* ScriptImporter.swift */,
				A10008 /* VLCPlayerViewController.swift */,
				A10009 /* PiPManager.swift */,
				A10010 /* FloatingPlayerManager.swift */,
				A10011 /* SubtitleManager.swift */,
				A10012 /* ScriptsViewController.swift */,
				A10013 /* BookmarksViewController.swift */,
				A10014 /* SettingsViewController.swift */,
				A10015 /* DataModels.swift */,
				A10016 /* Extensions.swift */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		A80001 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				INFOPLIST_FILE = MonkeyBrowser/Resources/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
				PRODUCT_BUNDLE_IDENTIFIER = com.monkeybrowser.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		A80002 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				INFOPLIST_FILE = MonkeyBrowser/Resources/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
				PRODUCT_BUNDLE_IDENTIFIER = com.monkeybrowser.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
		A80003 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				MTL_ENABLE_DEBUG_INFO = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
		A80004 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 5.0;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		A70001 /* Build configuration list for PBXNativeTarget "MonkeyBrowser" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A80001 /* Debug */,
				A80002 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		A70003 /* Build configuration list for PBXProject "MonkeyBrowser" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A80003 /* Debug */,
				A80004 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

	};
	rootObject = A60001 /* Project object */;
}
PBXEOF

echo "[2/3] 创建 scheme..."
mkdir -p MonkeyBrowser.xcodeproj/xcshareddata/xcschemes
cat > MonkeyBrowser.xcodeproj/xcshareddata/xcschemes/MonkeyBrowser.xcscheme << 'SCHEMEEOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1400"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "A50001"
               BuildableName = "MonkeyBrowser.app"
               BlueprintName = "MonkeyBrowser"
               ReferencedContainer = "container:MonkeyBrowser.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "A50001"
            BuildableName = "MonkeyBrowser.app"
            BlueprintName = "MonkeyBrowser"
            ReferencedContainer = "container:MonkeyBrowser.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
SCHEMEEOF

echo "[3/3] 完成!"
echo ""
echo "========================================="
echo "  项目已准备就绪!"
echo "========================================="
echo ""
echo "下一步:"
echo "1. 将此文件夹复制到 Mac"
echo "2. 在 Mac 上打开终端"
echo "3. cd MonkeyBrowser"
echo "4. chmod +x build.sh && ./build.sh"
echo ""
echo "或者使用 Xcode:"
echo "1. 双击 MonkeyBrowser.xcodeproj"
echo "2. 选择真机或模拟器"
echo "3. Cmd+R 运行"
echo ""

ARCHS = arm64
TARGET := iphone:clang:15.0:13.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MonkeyBrowser

MonkeyBrowser_FILES = $(shell find MonkeyBrowser/Sources -name "*.swift" -o -name "*.m" -o -name "*.h")
MonkeyBrowser_FRAMEWORKS = UIKit WebKit AVKit AVFoundation MobileVLCKit
MonkeyBrowser_PRIVATE_FRAMEWORKS = WebKit
MonkeyBrowser_CFLAGS = -fobjc-arc
MonkeyBrowser_SWIFT_FLAGS = -swift-version 5.7
MonkeyBrowser_LDFLAGS = -framework MobileVLCKit

include $(THEOS_MAKE_PATH)/application.mk

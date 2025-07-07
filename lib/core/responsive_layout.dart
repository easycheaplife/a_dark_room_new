import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 设备类型枚举
enum DeviceType {
  mobile,
  tablet,
  desktop,
  web,
}

/// 屏幕方向枚举
enum ScreenOrientation {
  portrait,
  landscape,
}

/// 响应式布局工具类
/// 用于检测设备类型、屏幕尺寸，并提供不同平台的布局参数
class ResponsiveLayout {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  /// 获取设备类型
  static DeviceType getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Web平台特殊处理
    if (kIsWeb) {
      if (screenWidth < mobileBreakpoint) {
        return DeviceType.mobile;
      } else if (screenWidth < tabletBreakpoint) {
        return DeviceType.tablet;
      } else {
        return DeviceType.web;
      }
    }
    
    // 移动平台
    if (screenWidth < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (screenWidth < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// 获取屏幕方向
  static ScreenOrientation getScreenOrientation(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height 
        ? ScreenOrientation.landscape 
        : ScreenOrientation.portrait;
  }

  /// 是否为移动设备
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// 是否为平板设备
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// 是否为桌面设备
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// 是否为Web平台
  static bool isWeb(BuildContext context) {
    return getDeviceType(context) == DeviceType.web;
  }

  /// 是否为横屏
  static bool isLandscape(BuildContext context) {
    return getScreenOrientation(context) == ScreenOrientation.landscape;
  }

  /// 是否为竖屏
  static bool isPortrait(BuildContext context) {
    return getScreenOrientation(context) == ScreenOrientation.portrait;
  }

  /// 获取安全区域内边距
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// 获取屏幕尺寸
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// 检测是否为微信浏览器
  /// 注意：此方法已移动到WebUtils类中，这里保留是为了向后兼容
  static bool isWeChatBrowser() {
    // 导入WebUtils会在编译时处理条件导入
    try {
      // 动态导入以避免在非Web平台出错
      return false; // 临时返回false，实际检测在WebUtils中
    } catch (e) {
      return false;
    }
  }

  /// 获取可用屏幕高度（减去安全区域）
  static double getAvailableHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return size.height - padding.top - padding.bottom;
  }

  /// 获取可用屏幕宽度（减去安全区域）
  static double getAvailableWidth(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return size.width - padding.left - padding.right;
  }
}

/// 游戏布局参数类
/// 根据设备类型提供不同的布局参数
class GameLayoutParams {
  final double gameAreaWidth;
  final double gameAreaHeight;
  final double notificationWidth;
  final double notificationHeight;
  final EdgeInsets contentPadding;
  final double buttonWidth;
  final double buttonHeight;
  final double buttonSpacing;
  final double fontSize;
  final double titleFontSize;
  final bool useVerticalLayout;
  final bool showNotificationOnSide;

  const GameLayoutParams({
    required this.gameAreaWidth,
    required this.gameAreaHeight,
    required this.notificationWidth,
    required this.notificationHeight,
    required this.contentPadding,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.buttonSpacing,
    required this.fontSize,
    required this.titleFontSize,
    required this.useVerticalLayout,
    required this.showNotificationOnSide,
  });

  /// 获取适合当前设备的布局参数
  static GameLayoutParams getLayoutParams(BuildContext context) {
    final deviceType = ResponsiveLayout.getDeviceType(context);
    final isLandscape = ResponsiveLayout.isLandscape(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return _getMobileLayoutParams(context, isLandscape);
      case DeviceType.tablet:
        return _getTabletLayoutParams(context, isLandscape);
      case DeviceType.desktop:
        return _getDesktopLayoutParams(context);
      case DeviceType.web:
        return _getWebLayoutParams(context);
    }
  }

  /// 移动设备布局参数
  static GameLayoutParams _getMobileLayoutParams(BuildContext context, bool isLandscape) {
    final availableWidth = ResponsiveLayout.getAvailableWidth(context);
    final availableHeight = ResponsiveLayout.getAvailableHeight(context);

    // 检测是否为Web平台的移动设备（包括微信浏览器）
    final isWebMobile = kIsWeb;

    if (isLandscape) {
      // 横屏模式 - 类似桌面布局但尺寸更小
      return GameLayoutParams(
        gameAreaWidth: availableWidth * 0.75,
        gameAreaHeight: availableHeight,
        notificationWidth: availableWidth * 0.25,
        notificationHeight: availableHeight * 0.8,
        contentPadding: EdgeInsets.all(isWebMobile ? 6.0 : 8.0), // Web端稍小的内边距
        buttonWidth: isWebMobile ? 90 : 100, // Web端稍小的按钮
        buttonHeight: isWebMobile ? 40 : 36, // Web端稍大的触摸区域
        buttonSpacing: 8.0,
        fontSize: isWebMobile ? 15 : 14, // Web端稍大的字体
        titleFontSize: isWebMobile ? 17 : 16,
        useVerticalLayout: false,
        showNotificationOnSide: true,
      );
    } else {
      // 竖屏模式 - 垂直布局
      return GameLayoutParams(
        gameAreaWidth: availableWidth,
        gameAreaHeight: availableHeight * (isWebMobile ? 0.88 : 0.85), // Web端更多游戏区域
        notificationWidth: availableWidth,
        notificationHeight: availableHeight * (isWebMobile ? 0.12 : 0.15), // Web端更少通知区域
        contentPadding: EdgeInsets.all(isWebMobile ? 10.0 : 12.0), // Web端稍小的内边距
        buttonWidth: (availableWidth - (isWebMobile ? 40 : 48)) / 2, // 两列布局，Web端调整间距
        buttonHeight: isWebMobile ? 52 : 48, // Web端更大的触摸区域（微信浏览器优化）
        buttonSpacing: isWebMobile ? 10.0 : 12.0, // Web端稍小的间距
        fontSize: isWebMobile ? 17 : 16, // Web端稍大的字体（微信浏览器优化）
        titleFontSize: isWebMobile ? 19 : 18,
        useVerticalLayout: true,
        showNotificationOnSide: false,
      );
    }
  }

  /// 平板设备布局参数
  static GameLayoutParams _getTabletLayoutParams(BuildContext context, bool isLandscape) {
    final availableWidth = ResponsiveLayout.getAvailableWidth(context);
    final availableHeight = ResponsiveLayout.getAvailableHeight(context);

    return GameLayoutParams(
      gameAreaWidth: isLandscape ? availableWidth * 0.8 : availableWidth,
      gameAreaHeight: isLandscape ? availableHeight : availableHeight * 0.9,
      notificationWidth: isLandscape ? availableWidth * 0.2 : availableWidth,
      notificationHeight: isLandscape ? availableHeight * 0.8 : availableHeight * 0.1,
      contentPadding: const EdgeInsets.all(16.0),
      buttonWidth: 120,
      buttonHeight: 40,
      buttonSpacing: 10.0,
      fontSize: 15,
      titleFontSize: 17,
      useVerticalLayout: !isLandscape,
      showNotificationOnSide: isLandscape,
    );
  }

  /// 桌面设备布局参数
  static GameLayoutParams _getDesktopLayoutParams(BuildContext context) {
    final screenWidth = ResponsiveLayout.getAvailableWidth(context);

    // 如果屏幕太小，使用较小的游戏区域
    final gameAreaWidth = screenWidth < 920 ? screenWidth * 0.75 : 700.0;
    final notificationWidth = screenWidth < 920 ? screenWidth * 0.2 : 200.0;

    return GameLayoutParams(
      gameAreaWidth: gameAreaWidth,
      gameAreaHeight: 700,
      notificationWidth: notificationWidth,
      notificationHeight: 700,
      contentPadding: const EdgeInsets.all(0),
      buttonWidth: gameAreaWidth < 700 ? 100 : 130,
      buttonHeight: 32,
      buttonSpacing: 5.0,
      fontSize: 14,
      titleFontSize: 16,
      useVerticalLayout: false,
      showNotificationOnSide: true,
    );
  }

  /// Web平台布局参数（保持原有设计，但确保居中）
  static GameLayoutParams _getWebLayoutParams(BuildContext context) {
    final screenWidth = ResponsiveLayout.getAvailableWidth(context);

    // 如果屏幕太小，使用较小的游戏区域
    final gameAreaWidth = screenWidth < 920 ? screenWidth * 0.75 : 700.0;
    final notificationWidth = screenWidth < 920 ? screenWidth * 0.2 : 200.0;

    return GameLayoutParams(
      gameAreaWidth: gameAreaWidth,
      gameAreaHeight: 700,
      notificationWidth: notificationWidth,
      notificationHeight: 700,
      contentPadding: const EdgeInsets.all(0),
      buttonWidth: gameAreaWidth < 700 ? 100 : 130,
      buttonHeight: 32,
      buttonSpacing: 5.0,
      fontSize: 14,
      titleFontSize: 16,
      useVerticalLayout: false,
      showNotificationOnSide: true,
    );
  }
}

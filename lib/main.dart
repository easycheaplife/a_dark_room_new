import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/state_manager.dart';
import 'core/engine.dart';
import 'core/audio_engine.dart';
import 'core/notifications.dart';
import 'core/localization.dart';
import 'core/responsive_layout.dart';
import 'core/logger.dart';
import 'core/progress_manager.dart';
import 'core/web_audio_adapter.dart';
import 'utils/web_utils.dart';
import 'utils/wechat_adapter.dart';

// import 'utils/performance_optimizer.dart'; // 暂时注释掉
import 'utils/storage_adapter.dart';
import 'widgets/header.dart';
import 'widgets/notification_display.dart';

import 'modules/room.dart';
import 'modules/outside.dart';
import 'modules/path.dart';
import 'modules/world.dart';
import 'modules/fabricator.dart';
import 'modules/ship.dart';
import 'modules/space.dart';
import 'modules/events.dart';
import 'screens/room_screen.dart';
import 'screens/outside_screen.dart';
import 'screens/path_screen.dart';
import 'screens/world_screen.dart';
import 'screens/fabricator_screen.dart';
import 'screens/ship_screen.dart';
import 'screens/space_screen.dart';
import 'screens/combat_screen.dart';
import 'screens/events_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Web平台初始化
  if (kIsWeb) {
    _initializeWebOptimizations();
  }

  // Set preferred orientations (移动端)
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const MyApp());
}

/// Web平台优化初始化
void _initializeWebOptimizations() async {
  try {
    // 初始化性能优化器 (暂时注释掉)
    // await PerformanceOptimizer.initialize();
    Logger.info('⚡ Performance optimizer skipped (mobile mode)');

    // 初始化存储适配器
    await StorageAdapter.initialize();
    Logger.info('📦 Storage adapter initialized');

    // 测试存储功能
    final storageTestResult = await StorageAdapter.testStorage();
    Logger.info('🧪 Storage test result: $storageTestResult');

    // 获取浏览器信息并记录日志
    final browserInfo = WebUtils.getBrowserInfo();
    Logger.info('🌐 Browser info: $browserInfo');

    // 初始化微信适配器
    await WeChatAdapter.initialize();

    // 初始化Web音频适配器
    await WebAudioAdapter.initialize();

    // 配置页面标题
    WebUtils.setPageTitle('A Dark Room - 黑暗房间');

    // 禁用页面默认行为
    WebUtils.disablePageDefaults();

    // 添加移动端优化CSS
    WebUtils.addMobileOptimizations();

    // 如果是微信浏览器，记录详细信息
    if (WeChatAdapter.isWeChatBrowser) {
      final wechatInfo = WeChatAdapter.getWeChatInfo();
      final featureSupport = WeChatAdapter.checkFeatureSupport();
      Logger.info('🔥 WeChat browser detected: $wechatInfo');
      Logger.info('🔧 WeChat feature support: $featureSupport');

      WebUtils.configWeChatShare(
        title: 'A Dark Room - 黑暗房间',
        desc: '一个引人入胜的文字冒险游戏，快来体验吧！',
      );
    }

    // 记录存储信息
    final storageInfo = await StorageAdapter.getStorageInfo();
    Logger.info('💾 Storage info: $storageInfo');

    // 记录性能统计 (暂时注释掉)
    // final performanceStats = PerformanceOptimizer.getPerformanceStats();
    Logger.info('📊 Performance stats: skipped (mobile mode)');

    Logger.info('✅ Web optimizations initialized successfully');
  } catch (e) {
    Logger.error('❌ Failed to initialize web optimizations: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StateManager()),
        ChangeNotifierProvider(create: (_) => NotificationManager()),
        ChangeNotifierProvider(create: (_) => Localization()),
        ChangeNotifierProvider(create: (_) => ProgressManager()),
        ChangeNotifierProvider(create: (_) => Engine()),
        ChangeNotifierProvider(create: (_) => Room()),
        ChangeNotifierProvider(create: (_) => Outside()),
        ChangeNotifierProvider(create: (_) => Path()),
        ChangeNotifierProvider(create: (_) => World()),
        ChangeNotifierProvider(create: (_) => Fabricator()),
        ChangeNotifierProvider(create: (_) => Ship()),
        ChangeNotifierProvider(create: (_) => Space()),
        ChangeNotifierProvider(create: (_) => Events()),
      ],
      child: Consumer<Localization>(
        builder: (context, localization, child) {
          return MaterialApp(
            title: 'A Dark Room',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.grey,
                brightness: Brightness.light, // 改为浅色主题
              ),
              scaffoldBackgroundColor: Colors.white, // 白色背景
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.black), // 黑色文字
                bodyLarge: TextStyle(color: Colors.black),
                titleMedium: TextStyle(color: Colors.black),
                titleLarge: TextStyle(color: Colors.black),
              ),
              useMaterial3: true,
            ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('zh'), // Chinese
              Locale('fr'), // French
              Locale('de'), // German
              Locale('es'), // Spanish
              Locale('ja'), // Japanese
              Locale('ko'), // Korean
              Locale('ru'), // Russian
            ],
            locale: Locale(localization.currentLanguage),
            home: const GameScreen(),
          );
        },
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize the localization and game engine
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Logger.info('🚀 Application starting...');
      Logger.info('🎨 App icon updated to assets/icon/icon.png');

      try {
        Logger.info('🌐 Initializing localization...');
        await Localization().init();
        Logger.info('✅ Localization initialization completed');

        Logger.info('🎮 Initializing game engine...');
        await Engine().init();
        Logger.info('✅ Game engine initialization completed');

        Logger.info('🎉 Application startup completed!');
      } catch (e) {
        Logger.error('❌ Application startup failed: $e');
      }
    });
  }

  @override
  void dispose() {
    // Clean up resources
    Engine().dispose();
    AudioEngine().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取布局参数
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    // 添加调试日志
    final screenSize = MediaQuery.of(context).size;
    final deviceType = ResponsiveLayout.getDeviceType(context);
    Logger.info(
        '📱 Device info - Screen size: ${screenSize.width}x${screenSize.height}, Device type: $deviceType, Vertical layout: ${layoutParams.useVerticalLayout}');

    return Scaffold(
      backgroundColor: Colors.white, // 原游戏使用白色背景
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            Engine().keyDown(event);
          } else if (event is KeyUpEvent) {
            Engine().keyUp(event);
          }
        },
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              // 处理用户交互以解锁Web音频
              if (kIsWeb) {
                WebAudioAdapter.handleUserInteraction();
              }
            },
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: layoutParams.useVerticalLayout
                  ? _buildMobileLayout(context, layoutParams)
                  : _buildDesktopLayout(context, layoutParams),
            ),
          ),
        ),
      ),
    );
  }

  /// 移动设备垂直布局
  Widget _buildMobileLayout(
      BuildContext context, GameLayoutParams layoutParams) {
    return Consumer<Engine>(
      builder: (context, engine, child) {
        final isWorldMode = engine.activeModule?.name == 'World';

        return Stack(
          children: [
            // 主布局
            Column(
              children: [
                // 主游戏区域
                Expanded(
                  child: SizedBox(
                    width: layoutParams.gameAreaWidth,
                    child: Column(
                      children: [
                        // Header导航 - 只在非世界地图模式显示
                        if (!isWorldMode) const Header(),

                        // 主面板区域
                        Expanded(
                          child: Consumer<Engine>(
                            builder: (context, engine, child) {
                              if (engine.activeModule == null) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return _buildActiveModulePanel(engine);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 通知区域 - 底部（修复：移动端事件日志显示在底部）
                if (!layoutParams.showNotificationOnSide)
                  SizedBox(
                    width: layoutParams.notificationWidth,
                    height: layoutParams.notificationHeight,
                    child: const NotificationDisplay(),
                  ),
              ],
            ),

            // 事件界面 - 全屏覆盖
            const Positioned.fill(
              child: EventsScreen(),
            ),

            // 战斗界面 - 全屏覆盖
            const Positioned.fill(
              child: CombatScreen(),
            ),
          ],
        );
      },
    );
  }

  /// 桌面/Web布局（保持原有设计）
  Widget _buildDesktopLayout(
      BuildContext context, GameLayoutParams layoutParams) {
    final screenSize = MediaQuery.of(context).size;

    // 计算居中位置 - 参考原游戏的布局
    // 原游戏总宽度是 700px + 220px padding = 920px
    final totalGameWidth = layoutParams.gameAreaWidth +
        (layoutParams.showNotificationOnSide
            ? layoutParams.notificationWidth + 20
            : 0);
    final leftOffset = (screenSize.width - totalGameWidth) / 2;

    return Stack(
      children: [
        // 通知区域 - 左侧固定位置（仅在桌面/Web显示）
        if (layoutParams.showNotificationOnSide)
          Positioned(
            left: leftOffset,
            top: 20,
            width: layoutParams.notificationWidth,
            height: layoutParams.notificationHeight,
            child: const NotificationDisplay(),
          ),

        // 主内容区域 - 居中显示
        Positioned(
          left: leftOffset +
              (layoutParams.showNotificationOnSide
                  ? layoutParams.notificationWidth + 20
                  : 0),
          top: 0,
          width: layoutParams.gameAreaWidth,
          height: layoutParams.gameAreaHeight,
          child: Consumer<Engine>(
            builder: (context, engine, child) {
              final isWorldMode = engine.activeModule?.name == 'World';

              return Column(
                children: [
                  // Header导航 - 只在非世界地图模式显示
                  if (!isWorldMode) const Header(),

                  // 主面板区域
                  Expanded(
                    child: Consumer<Engine>(
                      builder: (context, engine, child) {
                        if (engine.activeModule == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return _buildActiveModulePanel(engine);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 事件界面 - 全屏覆盖
        const Positioned.fill(
          child: EventsScreen(),
        ),

        // 战斗界面 - 全屏覆盖
        const Positioned.fill(
          child: CombatScreen(),
        ),
      ],
    );
  }

  Widget _buildActiveModulePanel(Engine engine) {
    // 根据当前活跃模块的类型显示对应的UI，添加切换动画
    final activeModule = engine.activeModule;

    if (activeModule == null) {
      return const RoomScreen(); // 默认显示房间
    }

    Widget screen;
    // 使用模块类型而不是name属性来判断
    if (activeModule is Room) {
      screen = const RoomScreen();
    } else if (activeModule is Outside) {
      screen = const OutsideScreen();
    } else if (activeModule is Path) {
      screen = const PathScreen();
    } else if (activeModule is World) {
      screen = const WorldScreen();
    } else if (activeModule is Fabricator) {
      screen = const FabricatorScreen();
    } else if (activeModule is Ship) {
      screen = const ShipScreen();
    } else if (activeModule is Space) {
      screen = const SpaceScreen();
    } else {
      // 未知模块类型，显示模块名称
      final moduleName = activeModule.name ?? 'Unknown';
      screen = Center(
        child: Text(
          'Module: $moduleName',
          style: const TextStyle(
            color: Colors.black, // 黑色文字
            fontSize: 24,
          ),
        ),
      );
    }

    // 添加页签切换动画
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300), // 300ms切换动画
      transitionBuilder: (Widget child, Animation<double> animation) {
        // 使用淡入淡出 + 轻微滑动的组合动画
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0), // 从右侧轻微滑入
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic, // 使用平滑的缓动曲线
            )),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(activeModule.runtimeType), // 使用模块类型作为key确保动画触发
        child: screen,
      ),
    );
  }
}

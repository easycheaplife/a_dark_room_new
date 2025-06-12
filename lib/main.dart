import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/state_manager.dart';
import 'core/engine.dart';
import 'core/audio_engine.dart';
import 'core/notifications.dart';
import 'core/localization.dart';
import 'widgets/header.dart';
import 'widgets/notification_display.dart';

import 'modules/room.dart';
import 'modules/outside.dart';
import 'modules/path.dart';
import 'modules/world.dart';
import 'modules/fabricator.dart';
import 'modules/ship.dart';
import 'modules/events.dart';
import 'screens/room_screen.dart';
import 'screens/outside_screen.dart';
import 'screens/path_screen.dart';
import 'screens/world_screen.dart';
import 'screens/fabricator_screen.dart';
import 'screens/ship_screen.dart';
import 'screens/combat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
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
        ChangeNotifierProvider(create: (_) => Engine()),
        ChangeNotifierProvider(create: (_) => Room()),
        ChangeNotifierProvider(create: (_) => Outside()),
        ChangeNotifierProvider(create: (_) => Path()),
        ChangeNotifierProvider(create: (_) => World()),
        ChangeNotifierProvider(create: (_) => Fabricator()),
        ChangeNotifierProvider(create: (_) => Ship()),
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

    // Initialize the game engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Engine().init();
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
          child: SizedBox(
            // 模拟原游戏的wrapper布局
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // 主内容区域
                Positioned(
                  left: 220, // 为通知区域留出空间
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Consumer<Engine>(
                    builder: (context, engine, child) {
                      // 检查是否在世界地图模式
                      final isWorldMode =
                          engine.activeModule?.name == 'World' ||
                              engine.activeModule?.name == '世界';

                      return SizedBox(
                        width: 700, // 原游戏的固定宽度
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
                      );
                    },
                  ),
                ),

                // 通知区域 - 左侧固定位置
                const Positioned(
                  left: 0,
                  top: 20,
                  width: 200,
                  height: 700,
                  child: NotificationDisplay(),
                ),

                // 战斗界面 - 全屏覆盖
                const Positioned.fill(
                  child: CombatScreen(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveModulePanel(Engine engine) {
    // 根据当前活跃模块显示对应的UI
    final activeModuleName = engine.activeModule?.name ?? 'Room';

    switch (activeModuleName) {
      case 'Room':
        return const RoomScreen();
      case 'Outside':
      case '外部': // 支持中文模块名
        return const OutsideScreen();
      case 'Path':
      case '漫漫尘途': // 支持中文模块名
        return const PathScreen();
      case 'World':
      case '世界': // 支持中文模块名
        return const WorldScreen();
      case 'Fabricator':
        return const FabricatorScreen();
      case 'Ship':
        return const ShipScreen();
      default:
        return Center(
          child: Text(
            'Module: $activeModuleName',
            style: const TextStyle(
              color: Colors.black, // 黑色文字
              fontSize: 24,
            ),
          ),
        );
    }
  }
}

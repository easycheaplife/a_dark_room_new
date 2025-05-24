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
import 'widgets/stores_display.dart';
import 'modules/room.dart';
import 'modules/outside.dart';
import 'modules/path.dart';
import 'modules/fabricator.dart';
import 'modules/ship.dart';

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
        ChangeNotifierProvider(create: (_) => Fabricator()),
        ChangeNotifierProvider(create: (_) => Ship()),
      ],
      child: Consumer<Localization>(
        builder: (context, localization, child) {
          return MaterialApp(
            title: 'A Dark Room',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.grey,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: Colors.black,
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white),
                bodyLarge: TextStyle(color: Colors.white),
                titleMedium: TextStyle(color: Colors.white),
                titleLarge: TextStyle(color: Colors.white),
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
          child: Column(
            children: [
              // Header with navigation tabs
              const Header(),

              // Main content area
              Expanded(
                child: Consumer<Engine>(
                  builder: (context, engine, child) {
                    // Show the active module's panel
                    if (engine.activeModule == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main content
                        Expanded(
                          child: _buildActiveModulePanel(engine),
                        ),

                        // Stores display (resources)
                        const StoresDisplay(),
                      ],
                    );
                  },
                ),
              ),

              // Notification area
              const NotificationDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveModulePanel(Engine engine) {
    // This would render the active module's panel
    // For now, we'll just show a placeholder
    return Center(
      child: Text(
        'Module: ${engine.activeModule?.name ?? "None"}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      ),
    );
  }
}

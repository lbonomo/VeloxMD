import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/viewer_screen.dart';
import 'services/keybindings_service.dart';

class VeloxMDApp extends StatefulWidget {
  const VeloxMDApp({super.key, this.initialFile, required this.keybindings});

  final String? initialFile;
  final KeybindingsService keybindings;

  @override
  State<VeloxMDApp> createState() => _VeloxMDAppState();
}

class _VeloxMDAppState extends State<VeloxMDApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
    );
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeloxMD',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        for (final activator in widget.keybindings[KeyAction.quit])
          activator: const _QuitIntent(),
      },
      actions: {
        ...WidgetsApp.defaultActions,
        _QuitIntent: CallbackAction<_QuitIntent>(
          onInvoke: (_) => windowManager.close(),
        ),
      },
      home: ViewerScreen(
        initialFile: widget.initialFile,
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        keybindings: widget.keybindings,
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
        brightness: Brightness.dark,
      ),
    );
  }
}

class _QuitIntent extends Intent {
  const _QuitIntent();
}

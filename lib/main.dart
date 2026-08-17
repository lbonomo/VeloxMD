import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/font_service.dart';
import 'services/keybindings_service.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(600, 400),
    center: true,
    title: 'VeloxMD',
    titleBarStyle: TitleBarStyle.normal,
    backgroundColor: Colors.transparent,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Support opening a file passed as a command-line argument.
  final String? initialFile = args.isNotEmpty ? args.first : null;

  // Keyboard shortcuts and fonts are resolved from the user's XDG/AppData
  // config instead of being hardcoded (see lib/services/).
  final keybindings = await KeybindingsService.load();
  final fonts = await FontService.load();

  runApp(VeloxMDApp(
    initialFile: initialFile,
    keybindings: keybindings,
    fonts: fonts,
  ));
}

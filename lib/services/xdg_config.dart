import 'dart:io';

import 'package:path/path.dart' as p;

/// VeloxMD's config directory: the XDG Base Directory Specification on
/// Linux/macOS (`$XDG_CONFIG_HOME/veloxmd`, falling back to
/// `~/.config/veloxmd`), and `%APPDATA%\veloxmd` on Windows. Shared by every
/// user-editable config file (keybindings, fonts, ...) so they all live next
/// to each other.
Directory veloxmdConfigDir() {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory(p.join(appData, 'veloxmd'));
    }
  }
  final xdgConfigHome = Platform.environment['XDG_CONFIG_HOME'];
  final home = Platform.environment['HOME'] ?? '.';
  final base = (xdgConfigHome != null && xdgConfigHome.isNotEmpty)
      ? xdgConfigHome
      : p.join(home, '.config');
  return Directory(p.join(base, 'veloxmd'));
}

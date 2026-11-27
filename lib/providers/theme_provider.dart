import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Menyimpan pilihan tema (system / light / dark) di Hive box `settings`.
class ThemeProvider extends ChangeNotifier {
  static const String boxName = 'settings';
  static const String _key = 'themeMode';

  ThemeMode _themeMode;

  ThemeProvider() : _themeMode = _read();

  static ThemeMode _read() {
    if (!Hive.isBoxOpen(boxName)) return ThemeMode.system;
    final name = Hive.box(boxName).get(_key) as String?;
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    if (Hive.isBoxOpen(boxName)) Hive.box(boxName).put(_key, mode.name);
    notifyListeners();
  }
}

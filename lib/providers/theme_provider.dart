import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _key = 'themeMode'; // 'system' | 'light' | 'dark'

  late final Box _box;
  ThemeMode _mode = ThemeMode.system;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box(_boxName);
    final raw = _box.get(_key) as String?;
    _mode = _fromString(raw);
    notifyListeners();
  }

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void setMode(ThemeMode m) {
    _mode = m;
    _box.put(_key, _toString(m));
    notifyListeners();
  }

  void toggleDark() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  String _toString(ThemeMode m) =>
      m == ThemeMode.system ? 'system' : (m == ThemeMode.dark ? 'dark' : 'light');

  ThemeMode _fromString(String? s) {
    if (s == 'dark') return ThemeMode.dark;
    if (s == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }
}
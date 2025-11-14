import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  late final Box _settingsBox;
  late ThemeMode _mode;

  ThemeProvider() {
    _settingsBox = Hive.box('settings');
    final stored = (_settingsBox.get('theme', defaultValue: 'light') as String);
    _mode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggleDark() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    _settingsBox.put('theme', isDark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    await _settingsBox.put('language', lang);
    notifyListeners();
  }
}
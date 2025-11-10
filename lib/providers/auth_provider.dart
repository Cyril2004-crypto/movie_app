import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class AuthProvider extends ChangeNotifier {
  static const _boxName = 'user';
  static const _key = 'username';

  late final Box _box;
  String? _username;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box(_boxName);
    _username = _box.get(_key) as String?;
    notifyListeners();
  }

  String? get username => _username;
  bool get isLoggedIn => _username != null && _username!.isNotEmpty;

  Future<void> login(String username) async {
    _username = username.trim();
    await _box.put(_key, _username);
    notifyListeners();
  }

  Future<void> logout() async {
    _username = null;
    await _box.delete(_key);
    notifyListeners();
  }
}
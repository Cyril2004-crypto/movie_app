import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AuthProvider extends ChangeNotifier {
  late final Box _userBox;

  AuthProvider() {
    _userBox = Hive.box('user'); // ensure opened in main.dart
  }

  bool get isLoggedIn => _userBox.get('loggedIn', defaultValue: false) as bool;
  String? get username => _userBox.get('username') as String?;

  // local/dev sign-in (username + password). Keeps behaviour similar to login().
  Future<void> signIn(String username, String password) async {
    // NOTE: mock auth for development only — replace with real auth as needed.
    await _userBox.put('loggedIn', true);
    await _userBox.put('username', username);
    notifyListeners();
  }

  // kept for compatibility with existing LoginScreen which calls login()
  Future<void> login(String username) async {
    await signIn(username, '');
  }

  Future<void> logout() async {
    await _userBox.put('loggedIn', false);
    await _userBox.delete('username');
    notifyListeners();
  }
}
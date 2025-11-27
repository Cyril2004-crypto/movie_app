import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthProvider extends ChangeNotifier {
  late final Box _userBox;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthProvider() {
    _userBox = Hive.box('user'); // ensure opened in main.dart
  }

  bool get isLoggedIn => _userBox.get('loggedIn', defaultValue: false) as bool;
  String? get username => _userBox.get('username') as String?;
  String? get provider => _userBox.get('provider') as String?;

  // Local/dev sign-in
  // helper: SHA256 hash used across register/login/change
  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  /// Try to change the current logged-in user's password.
  /// Returns true on success, false on failure.
  /// Use debugReason to get a short failure reason in logs (not shown to users).
  Future<bool> changePassword(String current, String next) async {
    try {
      final username = _userBox.get('username') as String?;
      if (username == null) {
        debugPrint('changePassword: no username in session');
        return false;
      }

      final usersRaw = _userBox.get('users', defaultValue: <String, String>{});
      final users = Map<String, String>.from(usersRaw as Map);
      final storedHash = users[username];

      if (storedHash == null) {
        debugPrint('changePassword: no stored credentials for user: $username');
        return false;
      }

      final currentHash = _hash(current);
      if (currentHash != storedHash) {
        debugPrint('changePassword: current password does not match for user: $username');
        return false;
      }

      // basic validation for new password
      if (next.length < 6) {
        debugPrint('changePassword: new password too short');
        return false;
      }

      users[username] = _hash(next);
      await _userBox.put('users', users);
      debugPrint('changePassword: password updated for user: $username');
      return true;
    } catch (e, st) {
      debugPrint('changePassword error: $e\n$st');
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    final users = Map<String, String>.from(_userBox.get('users', defaultValue: <String, String>{}));
    if (users.containsKey(username)) return false; // already exists
    users[username] = _hash(password);
    await _userBox.put('users', users);

    // auto-login after register
    await _userBox.put('loggedIn', true);
    await _userBox.put('username', username);
    await _userBox.put('provider', 'local');
    notifyListeners();
    return true;
  }

  Future<bool> loginWithPassword(String username, String password) async {
    final users = Map<String, String>.from(_userBox.get('users', defaultValue: <String, String>{}));
    final stored = users[username];
    if (stored == null) return false; // no such user
    if (stored != _hash(password)) return false; // wrong password

    await _userBox.put('loggedIn', true);
    await _userBox.put('username', username);
    await _userBox.put('provider', 'local');
    notifyListeners();
    return true;
  }

  // backwards-compatible helpers
  Future<void> signIn(String username, String password) async {
    // keep original behaviour by trying password login (works for both)
    await loginWithPassword(username, password);
  }

  Future<void> login(String username) async => await signIn(username, '');
  Future<void> logout() async {
    await _userBox.put('loggedIn', false);
    await _userBox.delete('username');
    await _userBox.delete('email');
    await _userBox.delete('avatar');
    await _userBox.delete('provider');
    notifyListeners();
  }

  // Google sign-in (client SDK). Returns true on success.
  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false; // user cancelled

      // optionally get tokens:
      final auth = await account.authentication;

      final name = account.displayName;
      final email = account.email;
      final photoUrl = account.photoUrl;

      await _userBox.put('loggedIn', true);
      await _userBox.put('username', name ?? email);
      await _userBox.put('email', email);
      await _userBox.put('avatar', photoUrl);
      await _userBox.put('provider', 'google');

      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('Google sign-in error: $e\n$st');
      return false;
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await logout();
  }

  // Facebook sign-in (already present in file previously)
  Future<bool> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(fields: "name,email,picture.width(200)");
        final name = userData['name'] as String?;
        final email = userData['email'] as String?;
        final picture = (userData['picture']?['data']?['url']) as String?;

        await _userBox.put('loggedIn', true);
        await _userBox.put('username', name ?? email ?? 'FacebookUser');
        await _userBox.put('email', email);
        await _userBox.put('avatar', picture);
        await _userBox.put('provider', 'facebook');

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      debugPrint('Facebook sign-in error: $e\n$st');
      return false;
    }
  }

  // Placeholder for Apple Sign-In — replace with real sign_in_with_apple flow after platform setup
  Future<bool> signInWithApple() async {
    try {
      // TODO: implement real Sign in with Apple:
      // final credential = await SignInWithApple.getAppleIDCredential(...);
      // verify credential on backend or extract user info and persist.

      // For now perform a mock sign-in so UI flows work
      await _userBox.put('loggedIn', true);
      await _userBox.put('username', 'AppleUser');
      await _userBox.put('provider', 'apple');
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('Apple sign-in error: $e\n$st');
      return false;
    }
  }

  Future<void> signOutApple() async {
    // TODO: call real sign out / revoke if using real Apple sign-in
    await _userBox.put('loggedIn', false);
    await _userBox.delete('username');
    await _userBox.delete('provider');
    notifyListeners();
  }

  Future<void> updateUsername(String newName) async {
    await _userBox.put('username', newName);
    notifyListeners();
  }

  // simple JSON export for user data
  Future<String?> exportUserData() async {
    final data = {
      'username': _userBox.get('username'),
      'provider': _userBox.get('provider'),
      'watchlist': _userBox.get('watchlist'),
      'favorites': _userBox.get('favorites'),
    };
    // write to app directory or share — for now persist to a file in app docs directory
    // implement using path_provider + dart:io as needed; return path string
    return null; // implement file write and return path
  }

  // delete account (local-only). For social/provider-backed accounts you must call backend.
  Future<bool> deleteAccount({required bool localOnly}) async {
    // local-only: remove user entry and clear session
    try {
      final username = _userBox.get('username') as String?;
      if (username != null) {
        final users = Map<String,String>.from(_userBox.get('users', defaultValue: <String,String>{}));
        users.remove(username);
        await _userBox.put('users', users);
      }
      await logout();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Debug helper to inspect stored users in Hive (call from a debug button)
  Map<String, String> debugListUsers() {
    final raw = _userBox.get('users', defaultValue: <String, String>{});
    try {
      return Map<String, String>.from(raw as Map);
    } catch (_) {
      return <String, String>{};
    }
  }
}
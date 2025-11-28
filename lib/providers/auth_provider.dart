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

  // helper: SHA256 hash used across register/login/change
  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  /// Returns null on success, otherwise a short error message explaining failure.
  Future<String?> changePasswordWithReason(String current, String next) async {
    try {
      final username = _userBox.get('username') as String?;
      if (username == null) {
        debugPrint('changePasswordWithReason: no username in session');
        return 'No user is currently signed in';
      }

      final provider = _userBox.get('provider') as String?;

      final usersRaw = _userBox.get('users', defaultValue: <String, String>{});
      final users = Map<String, String>.from(usersRaw as Map);

      // case-insensitive key lookup to avoid mismatch
      final matchedKey = users.keys.firstWhere(
        (k) => k.toLowerCase() == username.toLowerCase(),
        orElse: () => '',
      );
      if (matchedKey.isEmpty) {
        debugPrint('changePasswordWithReason: no stored credentials for user: $username');
        if (provider != null && provider != 'local') {
          return 'Account is managed by $provider — create a local password to enable local password changes';
        }
        return 'No stored credentials for $username';
      }

      final storedHash = users[matchedKey];
      if (storedHash == null) {
        debugPrint('changePasswordWithReason: null storedHash for key $matchedKey');
        return 'No stored credentials for $username';
      }

      final currentHash = _hash(current);
      if (currentHash != storedHash) {
        debugPrint('changePasswordWithReason: provided current password does not match for user: $username');
        return 'Current password is incorrect';
      }

      if (next.length < 6) {
        debugPrint('changePasswordWithReason: new password too short');
        return 'New password must be at least 6 characters';
      }

      users[matchedKey] = _hash(next);
      await _userBox.put('users', users);
      debugPrint('changePasswordWithReason: password updated for user: $username');
      return null;
    } catch (e, st) {
      debugPrint('changePasswordWithReason error: $e\n$st');
      return 'Unexpected error';
    }
  }

  // boolean wrapper for compatibility
  Future<bool> changePassword(String current, String next) async {
    final err = await changePasswordWithReason(current, next);
    return err == null;
  }

  /// Create (or overwrite) a local password entry for the currently signed-in username.
  /// Useful for users who signed in via social providers and want a local password.
  Future<String?> createLocalPasswordForCurrentUser(String newPassword) async {
    try {
      final username = _userBox.get('username') as String?;
      if (username == null) return 'No user is currently signed in';
      if (newPassword.length < 6) return 'New password must be at least 6 characters';

      final usersRaw = _userBox.get('users', defaultValue: <String, String>{});
      final users = Map<String, String>.from(usersRaw as Map);

      // store using the canonical username as key (preserve case)
      users[username] = _hash(newPassword);
      await _userBox.put('users', users);

      debugPrint('createLocalPasswordForCurrentUser: created local password for $username');
      return null;
    } catch (e, st) {
      debugPrint('createLocalPasswordForCurrentUser error: $e\n$st');
      return 'Unexpected error';
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

  Future<bool> signInWithApple() async {
    try {
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
    await _userBox.put('loggedIn', false);
    await _userBox.delete('username');
    await _userBox.delete('provider');
    notifyListeners();
  }

  Future<void> updateUsername(String newName) async {
    await _userBox.put('username', newName);
    notifyListeners();
  }

  Future<String?> exportUserData() async {
    final data = {
      'username': _userBox.get('username'),
      'provider': _userBox.get('provider'),
      'watchlist': _userBox.get('watchlist'),
      'favorites': _userBox.get('favorites'),
    };
    return null;
  }

  Future<bool> deleteAccount({required bool localOnly}) async {
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

  Map<String, String> debugListUsers() {
    final raw = _userBox.get('users', defaultValue: <String, String>{});
    try {
      return Map<String, String>.from(raw as Map);
    } catch (_) {
      return <String, String>{};
    }
  }
}
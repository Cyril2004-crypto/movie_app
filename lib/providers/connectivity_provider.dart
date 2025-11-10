import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _conn = Connectivity();
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    final res = await _conn.checkConnectivity();
    _isOnline = res != ConnectivityResult.none;
    notifyListeners();
    _conn.onConnectivityChanged.listen((result) {
      final online = result != ConnectivityResult.none;
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }
}
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateStatus(results);
    } catch (_) {
      await checkRealInternet();
    }
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    bool hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) {
      // Don't trust connectivity_plus alone when switching networks or on mobile data:
      // Verify via actual socket/DNS lookup!
      hasConnection = await checkRealInternet();
    } else {
      _setConnected(true);
    }
  }

  void _setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _controller.add(connected);
      notifyListeners();
    }
  }

  /// Performs a fast real-world DNS/socket check to verify internet reachability.
  Future<bool> checkRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _setConnected(true);
        return true;
      }
    } catch (_) {
      try {
        final result = await InternetAddress.lookup('supabase.co')
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _setConnected(true);
          return true;
        }
      } catch (_) {}
    }
    _setConnected(false);
    return false;
  }

  /// Explicit check that can be awaited before network operations.
  Future<bool> verifyConnection() async {
    final results = await _connectivity.checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      _setConnected(true);
      return true;
    }
    return await checkRealInternet();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

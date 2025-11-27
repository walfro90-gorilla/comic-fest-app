import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (wasOnline != _isOnline) {
      debugPrint(_isOnline ? '📶 Online' : '📵 Offline');
      _connectivityController.add(_isOnline);
    }
  }

  void dispose() {
    _connectivityController.close();
  }
}

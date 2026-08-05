import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Watches device network status and exposes a simple online/offline flag.
class ConnectivityService extends GetxService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  static const offlineMessage =
      'No internet connection. Please check your network and try again.';

  final Connectivity _connectivity;
  final RxBool isOnline = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<ConnectivityService> init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      isOnline.value = true; // fail open so the app can still attempt requests
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (Object e) => debugPrint('Connectivity stream error: $e'),
    );
    return this;
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other,
    );
    if (isOnline.value != online) {
      isOnline.value = online;
      debugPrint('Connectivity => ${online ? 'online' : 'offline'} ($results)');
    }
  }

  void ensureOnline() {
    if (!isOnline.value) {
      throw Exception(offlineMessage);
    }
  }

  Future<bool> refresh() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (_) {}
    return isOnline.value;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Improves HTTPS trust on older Android devices for hosts using newer CA chains
/// (e.g. Sectigo E46 / cPanel intermediates).
class AppHttpOverrides extends HttpOverrides {
  AppHttpOverrides(this._securityContext);

  final SecurityContext _securityContext;

  static Future<AppHttpOverrides> create() async {
    final context = SecurityContext(withTrustedRoots: true);
    for (final asset in const <String>[
      'assets/certs/cpanel_intermediate.pem',
      'assets/certs/sectigo_e46_cross.pem',
    ]) {
      try {
        final data = await rootBundle.load(asset);
        context.setTrustedCertificatesBytes(data.buffer.asUint8List());
      } catch (e) {
        debugPrint('Failed to load trusted cert $asset: $e');
      }
    }
    return AppHttpOverrides(context);
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(_securityContext);
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 30);
    return client;
  }
}

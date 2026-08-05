import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/services/connectivity_service.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

/// Top banner shown while the device reports no network connection.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();

    return Obx(() {
      final offline = !connectivity.isOnline.value;
      return Column(
        children: [
          if (offline)
            Material(
              color: const Color(0xFFB42318),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No internet connection',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => connectivity.refresh(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      );
    });
  }
}

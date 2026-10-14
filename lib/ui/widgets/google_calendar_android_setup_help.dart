import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leavego_app/config/google_calendar_config.dart';

/// Shown on Android when [GoogleCalendarConfig.webClientId] is missing.
class GoogleCalendarAndroidSetupHelp extends StatelessWidget {
  const GoogleCalendarAndroidSetupHelp({super.key});

  static const String debugSha1 = 'B4:4D:3D:EE:48:D9:EC:A9:1D:98:B8:26:3A:D1:3B:08:E5:0A:25:81';
  static const String debugSha256 =
      '98:91:3C:63:03:FA:0F:BB:22:E5:4E:BA:4D:C8:BF:28:90:99:9D:74:FE:BD:1A:21:A7:09:B3:6F:9F:76:65:18';

  static bool get shouldShow => Platform.isAndroid && GoogleCalendarConfig.webClientId == null;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Android setup (one time)',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Open Google Cloud Console → project 196388059648 → APIs & Services → Credentials.\n'
            '2. Edit your Android OAuth client → add SHA-1 and SHA-256 below → package com.devbay.taskbulls.\n'
            '3. Create OAuth client → type Web application → copy the Client ID.\n'
            '4. Put that Web Client ID in lib/config/google_calendar_config.dart as GOOGLE_OAUTH_WEB_CLIENT_ID defaultValue (or ask your developer).\n'
            '5. Rebuild the app (full restart, not hot reload).',
            style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 12),
          _CopyRow(label: 'Debug SHA-1', value: debugSha1),
          const SizedBox(height: 6),
          _CopyRow(label: 'Debug SHA-256', value: debugSha256),
          const SizedBox(height: 8),
          Text(
            'Android client ID (already in app): ${GoogleCalendarConfig.androidClientId ?? "—"}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, color: Color(0xFF444444), height: 1.3),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value, style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.copy_rounded, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied $label')),
            );
          },
        ),
      ],
    );
  }
}

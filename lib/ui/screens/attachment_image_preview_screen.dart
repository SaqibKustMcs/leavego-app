import 'dart:io';

import 'package:flutter/material.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';

class AttachmentImagePreviewScreen extends StatelessWidget {
  const AttachmentImagePreviewScreen({
    super.key,
    required this.file,
    required this.title,
  });

  final File file;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(color: Colors.white),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not display this image.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

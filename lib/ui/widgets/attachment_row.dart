import 'package:flutter/material.dart';

/// Attachment picker row with document, gallery, and camera actions (Create Task / Apply Leave).
class AttachmentRow extends StatelessWidget {
  const AttachmentRow({
    super.key,
    required this.attachmentName,
    required this.onDocument,
    required this.onGallery,
    required this.onCamera,
    this.borderColor,
  });

  static const String documentIcon = 'assets/images/document-text-sharp.webp';
  static const String galleryIcon = 'assets/images/images-galary.webp';
  static const String cameraIcon = 'assets/images/camera-plus-outline.webp';

  final String? attachmentName;
  final VoidCallback onDocument;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final Color? borderColor;

  static const Color _primary = Color(0xFF173559);
  static const Color _defaultFieldBorder = Color(0xFFEEF4F2);

  @override
  Widget build(BuildContext context) {
    final fieldBorder = borderColor ?? _defaultFieldBorder;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fieldBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              attachmentName ?? 'Add Attachment',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _primary),
            ),
          ),
          _AttachmentIconButton(asset: documentIcon, onTap: onDocument),
          Container(
            width: 1,
            height: 28,
            color: fieldBorder,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _AttachmentIconButton(asset: galleryIcon, onTap: onGallery),
          Container(
            width: 1,
            height: 28,
            color: fieldBorder,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _AttachmentIconButton(asset: cameraIcon, onTap: onCamera),
        ],
      ),
    );
  }
}

class _AttachmentIconButton extends StatelessWidget {
  const _AttachmentIconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(asset, width: 24, height: 24, fit: BoxFit.contain),
      ),
    );
  }
}

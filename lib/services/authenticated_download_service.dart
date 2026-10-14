import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leavego_app/ui/screens/attachment_image_preview_screen.dart';
import 'package:leavego_app/utils/attachment_file_type.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthenticatedAttachmentFile {
  const AuthenticatedAttachmentFile({
    required this.path,
    required this.fileName,
    required this.kind,
    required this.mimeType,
  });

  final String path;
  final String fileName;
  final AttachmentOpenKind kind;
  final String? mimeType;
}

/// Downloads private task attachments with bearer auth and opens by file type.
class AuthenticatedDownloadService {
  const AuthenticatedDownloadService();

  Future<AuthenticatedAttachmentFile?> downloadAttachment({
    required String url,
    required String token,
    String? fileNameHint,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || token.trim().isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    try {
      final response = await http.get(
        uri,
        headers: <String, String>{'Authorization': 'Bearer ${token.trim()}'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final fileName = _resolveFileName(
        uri: uri,
        fileNameHint: fileNameHint,
        contentDisposition: response.headers['content-disposition'],
      );
      final contentType = response.headers['content-type'];
      final kind = AttachmentFileType.kindFor(fileName: fileName, contentType: contentType);
      final mimeType = AttachmentFileType.mimeFor(fileName: fileName, contentType: contentType);

      final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final file = File('${Directory.systemTemp.path}/taskbulls_$safeName');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      return AuthenticatedAttachmentFile(
        path: file.path,
        fileName: fileName,
        kind: kind,
        mimeType: mimeType,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> openAttachment({
    required String url,
    required String token,
    String? fileNameHint,
    BuildContext? context,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || token.trim().isEmpty) return false;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;

    final local = await downloadAttachment(
      url: url,
      token: token,
      fileNameHint: fileNameHint,
    );
    if (local != null) {
      return openLocalFile(local, context: context);
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openLocalFile(
    AuthenticatedAttachmentFile file, {
    BuildContext? context,
  }) async {
    if (file.kind == AttachmentOpenKind.image && context != null) {
      if (!context.mounted) return false;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AttachmentImagePreviewScreen(
            file: File(file.path),
            title: file.fileName,
          ),
        ),
      );
      return true;
    }

    final result = await OpenFilex.open(
      file.path,
      type: file.mimeType,
    );
    return result.type == ResultType.done;
  }

  String _resolveFileName({
    required Uri uri,
    String? fileNameHint,
    String? contentDisposition,
  }) {
    final fromHeader = _fileNameFromContentDisposition(contentDisposition);
    if (fromHeader != null && fromHeader.isNotEmpty) return fromHeader;

    final hint = fileNameHint?.trim();
    if (hint != null && hint.isNotEmpty) return hint;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final last = segments.last;
      if (last.contains('.')) return last;
    }
    return 'attachment';
  }

  String? _fileNameFromContentDisposition(String? header) {
    if (header == null || header.trim().isEmpty) return null;
    final filenameStar = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false).firstMatch(header);
    if (filenameStar != null) {
      return Uri.decodeComponent(filenameStar.group(1)!.trim());
    }
    final filename = RegExp(r'filename="?([^";]+)"?', caseSensitive: false).firstMatch(header);
    return filename?.group(1)?.trim();
  }
}

enum AttachmentOpenKind { image, pdf, other }

class AttachmentFileType {
  AttachmentFileType._();

  static AttachmentOpenKind kindFor({required String fileName, String? contentType}) {
    final mime = _normalizeMime(contentType);
    if (mime.startsWith('image/')) return AttachmentOpenKind.image;
    if (mime == 'application/pdf') return AttachmentOpenKind.pdf;

    final ext = extensionFromName(fileName);
    if (_imageExtensions.contains(ext)) return AttachmentOpenKind.image;
    if (ext == 'pdf') return AttachmentOpenKind.pdf;
    return AttachmentOpenKind.other;
  }

  static String? mimeFor({required String fileName, String? contentType}) {
    final mime = _normalizeMime(contentType);
    if (mime.isNotEmpty) return mime;

    switch (extensionFromName(fileName)) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      default:
        return null;
    }
  }

  static String extensionFromName(String fileName) {
    final name = fileName.trim().toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot >= name.length - 1) return '';
    return name.substring(dot + 1);
  }

  static const _imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };

  static String _normalizeMime(String? raw) {
    if (raw == null) return '';
    final value = raw.split(';').first.trim().toLowerCase();
    return value;
  }
}

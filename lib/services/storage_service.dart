import 'dart:io';

/// Reference to an attachment for UI preview and local storage.
class Attachment {
  const Attachment({
    required this.url,
    required this.path,
    required this.name,
  });

  final String url;
  final String path;
  final String name;
}

/// Standalone storage service for UI view.
class StorageService {
  StorageService();

  static const int maxBytes = 5 * 1024 * 1024;

  static const List<String> allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'pdf',
    'doc',
    'docx',
    'txt',
  ];

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  static bool isAllowedFileName(String fileName) =>
      allowedExtensions.contains(_extensionOf(fileName));

  Future<Attachment> upload({
    required String taskId,
    required File file,
    required String fileName,
  }) async {
    return Attachment(url: file.path, path: file.path, name: fileName);
  }

  Future<void> delete(String path) async {
    // No-op for UI view
  }
}

import 'dart:io';
import '../config/app_config.dart';

class FileSizeValidator {
  static bool isValidSize(File file) {
    return file.lengthSync() <= AppConfig.maxFileSizeBytes;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileTooLargeException implements Exception {
  String get message => 'File exceeds the 30MB limit. Please choose a smaller file.';
  
  @override
  String toString() => message;
}

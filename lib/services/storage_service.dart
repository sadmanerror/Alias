import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class FileTooLargeException implements Exception {
  final String message;
  FileTooLargeException(this.message);
  @override
  String toString() => message;
}

/// Free, subscription-less storage service that uploads media to free cloud storage
/// (Catbox API) with Base64 fallback for images, requiring no paid Firebase Storage subscription.
class StorageService {
  final _uploadProgressController = StreamController<double>.broadcast();

  StorageService([dynamic _]);

  Stream<double> get uploadProgress => _uploadProgressController.stream;

  /// Uploads media file (image, video, audio, document) for free without Firebase Storage
  Future<String> uploadMedia({
    required File file,
    required String chatId,
    required String messageType,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = '${const Uuid().v4()}.$ext';

    return uploadMediaBytes(
      bytes: bytes,
      fileName: fileName,
      messageType: messageType,
    );
  }

  /// Uploads raw bytes directly (compatible with Flutter Web, Android, iOS)
  Future<String> uploadMediaBytes({
    required List<int> bytes,
    required String fileName,
    required String messageType,
  }) async {
    if (bytes.length > 30 * 1024 * 1024) {
      throw FileTooLargeException('File size exceeds 30MB limit');
    }

    _uploadProgressController.add(0.2);

    try {
      // 1. Try free cloud upload via Catbox (supports images, audio, video, files up to 200MB)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://catbox.moe/user/api.php'),
      );
      request.fields['reqtype'] = 'fileupload';
      request.files.add(
        http.MultipartFile.fromBytes('fileToUpload', bytes, filename: fileName),
      );

      _uploadProgressController.add(0.5);
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      _uploadProgressController.add(0.8);

      if (streamedResponse.statusCode == 200) {
        final body = await streamedResponse.stream.bytesToString();
        final url = body.trim();
        if (url.startsWith('http')) {
          _uploadProgressController.add(1.0);
          return url;
        }
      }
    } catch (_) {
      // Free cloud upload timed out or failed - fallback to Base64
    }

    // 2. Base64 fallback (works for images and audio without any external server)
    if (messageType == 'image') {
      final base64Str = base64Encode(bytes);
      final ext = fileName.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      _uploadProgressController.add(1.0);
      return 'data:$mime;base64,$base64Str';
    }

    if (messageType == 'audio') {
      final base64Str = base64Encode(bytes);
      _uploadProgressController.add(1.0);
      return 'data:audio/m4a;base64,$base64Str';
    }

    throw Exception('Failed to upload file. Please check your internet connection.');
  }

  /// Uploads a profile photo for free from device and returns URL / Base64 string
  Future<String> uploadProfilePhoto(File file, String uid) async {
    final bytes = await file.readAsBytes();
    return uploadProfilePhotoBytes(bytes, 'profile_$uid.jpg');
  }

  /// Uploads profile photo from bytes (works on Web and Mobile)
  Future<String> uploadProfilePhotoBytes(List<int> bytes, String fileName) async {
    // For profile photos, convert directly to Base64 data URI (fast, zero server dependency)
    if (bytes.length <= 500 * 1024) {
      final base64Str = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Str';
    }

    // If large, upload via free cloud storage
    return uploadMediaBytes(
      bytes: bytes,
      fileName: fileName,
      messageType: 'image',
    );
  }

  /// Uploads voice recording for free
  Future<String> uploadVoiceMessage(File file, String chatId) async {
    final bytes = await file.readAsBytes();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return uploadMediaBytes(
      bytes: bytes,
      fileName: 'voice_$timestamp.m4a',
      messageType: 'audio',
    );
  }

  Future<void> deleteMedia(String url) async {
    // No-op for free storage
  }

  void dispose() {
    _uploadProgressController.close();
  }
}

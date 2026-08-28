import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FileTooLargeException implements Exception {
  final String message;
  FileTooLargeException(this.message);
  @override
  String toString() => message;
}

class StorageService {
  final FirebaseStorage _storage;
  final _uploadProgressController = StreamController<double>.broadcast();

  StorageService(this._storage);

  Stream<double> get uploadProgress => _uploadProgressController.stream;

  Future<String> uploadMedia({
    required File file,
    required String chatId,
    required String messageType,
  }) async {
    final fileSize = await file.length();
    if (fileSize > 30 * 1024 * 1024) {
      throw FileTooLargeException('File size exceeds 30MB limit');
    }

    final uuid = const Uuid().v4();
    final ext = file.path.split('.').last;
    final ref = _storage.ref().child('chats/$chatId/$messageType/$uuid.$ext');

    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      _uploadProgressController.add(progress);
    });

    await uploadTask;
    _uploadProgressController.add(0.0);
    return await ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto(File file, String uid) async {
    final ref = _storage.ref().child('users/$uid/profile.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadVoiceMessage(File file, String chatId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('chats/$chatId/audio/$timestamp.m4a');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> deleteMedia(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Handle error or ignore if already deleted
    }
  }
  
  void dispose() {
    _uploadProgressController.close();
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alias/models/message_model.dart';
import 'package:alias/core/utils/file_size_validator.dart';

class MediaPickerSheet extends StatelessWidget {
  final Function(File file, MessageType type) onFilePicked;

  const MediaPickerSheet({super.key, required this.onFilePicked});

  static const Color primarySageGreen = Color(0xFF8DA399);

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      if (!await _requestPermission(Permission.camera)) return;
    } else {
      if (!await _requestPermission(Permission.photos)) return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      _processFile(context, File(pickedFile.path), MessageType.image);
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    if (!await _requestPermission(Permission.videos)) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      _processFile(context, File(pickedFile.path), MessageType.video);
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      _processFile(context, File(result.files.single.path!), MessageType.file);
    }
  }

  void _processFile(BuildContext context, File file, MessageType type) {
    if (!FileSizeValidator.isValidSize(file)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File exceeds the 30MB limit.')),
      );
      return;
    }
    onFilePicked(file, type);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildOption(
                    context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.pink,
                    onTap: () => _pickImage(context, ImageSource.camera),
                  ),
                  _buildOption(
                    context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () => _pickImage(context, ImageSource.gallery),
                  ),
                  _buildOption(
                    context,
                    icon: Icons.videocam,
                    label: 'Video',
                    color: Colors.orange,
                    onTap: () => _pickVideo(context),
                  ),
                  _buildOption(
                    context,
                    icon: Icons.attach_file,
                    label: 'File',
                    color: Colors.blue,
                    onTap: () => _pickFile(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF2C3E35))),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IdCardPicker extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String?> onImagePicked;
  const IdCardPicker({super.key, this.imagePath, required this.onImagePicked});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );
    if (source != null) {
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        onImagePicked(picked.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            if (imagePath != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(imagePath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: const Icon(
                  Icons.credit_card,
                  size: 32,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(context),
                icon: const Icon(Icons.upload_file),
                label: Text(imagePath == null ? 'Upload ID Card' : 'Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

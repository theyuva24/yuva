import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../universal/theme/app_theme.dart';

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
    final isUploaded = imagePath != null && imagePath!.isNotEmpty;
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppThemeLight.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemeLight.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child:
            isUploaded
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: AppThemeLight.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Click here to upload ID',
                      style: TextStyle(
                        color: AppThemeLight.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProfileImagePicker extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String?> onImagePicked;
  const ProfileImagePicker({
    super.key,
    this.imagePath,
    required this.onImagePicked,
  });

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
        // Compress the image
        final compressed = await FlutterImageCompress.compressAndGetFile(
          picked.path,
          '${picked.path}_compressed.jpg',
          quality: 70,
        );
        onImagePicked(compressed != null ? compressed.path : picked.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage:
                  imagePath != null ? FileImage(File(imagePath!)) : null,
              backgroundColor: Colors.transparent,
              child:
                  imagePath == null
                      ? const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white70,
                      )
                      : null,
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: InkWell(
                onTap: () => _pickImage(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 2),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 20,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

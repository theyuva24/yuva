import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../initial pages/auth_service.dart';
import '../service/submission_service.dart';
import '../model/submission_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmitEntryPage extends StatefulWidget {
  final Challenge challenge;
  const SubmitEntryPage({Key? key, required this.challenge}) : super(key: key);

  @override
  State<SubmitEntryPage> createState() => _SubmitEntryPageState();
}

class _SubmitEntryPageState extends State<SubmitEntryPage> {
  File? _selectedImage;
  File? _selectedVideo;
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedVideo = File(picked.path);
      });
    }
  }

  void _submit() async {
    setState(() {
      _submitting = true;
    });
    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('User not logged in');
      final userId = user.uid;
      final challengeId = widget.challenge.id;
      String? mediaUrl;
      final submissionService = SubmissionService();
      // Only upload media if either image or video is selected
      if (_selectedImage != null || _selectedVideo != null) {
        final file = _selectedImage ?? _selectedVideo!;
        mediaUrl = await submissionService.uploadMedia(
          file,
          userId,
          challengeId,
        );
      } else {
        mediaUrl = null; // Explicitly allow no media
      }
      final submission = Submission(
        id: '',
        challengeId: challengeId,
        userId: userId,
        mediaUrl: mediaUrl,
        caption: _captionController.text.trim(),
        timestamp: Timestamp.now(),
        status: 'pending',
      );
      print('Submission data: ${submission.toMap()}');
      print('Current user UID: ${userId}');
      await submissionService.addSubmission(submission);
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entry submitted!')));
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challenge: ${widget.challenge.title}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text('Image', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child:
                    _selectedImage != null
                        ? Image.file(_selectedImage!, height: 150)
                        : Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
              ),
              const SizedBox(height: 24),
              Text('Video', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickVideo,
                child:
                    _selectedVideo != null
                        ? Row(
                          children: [
                            const Icon(
                              Icons.videocam,
                              size: 40,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_selectedVideo!.path.split('/').last),
                            ),
                          ],
                        )
                        : Container(
                          height: 60,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.add_to_photos,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
              ),
              const SizedBox(height: 24),
              Text('Caption', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _captionController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a caption for your entry',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child:
                      _submitting
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Submit Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

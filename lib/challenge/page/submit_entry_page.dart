import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../initial pages/auth_service.dart';
import '../service/submission_service.dart';
import '../model/submission_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../service/background_submission_service.dart';

class SubmitEntryPage extends StatefulWidget {
  final Challenge challenge;
  const SubmitEntryPage({Key? key, required this.challenge}) : super(key: key);

  @override
  State<SubmitEntryPage> createState() => _SubmitEntryPageState();
}

class _SubmitEntryPageState extends State<SubmitEntryPage> {
  File? _selectedImage;
  File? _selectedVideo;
  File? _videoThumbnailFile;
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
      // Generate thumbnail for preview (lightweight operation)
      try {
        final thumbPath = await VideoThumbnail.thumbnailFile(
          video: picked.path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.PNG,
          maxHeight: 320,
          quality: 75,
        );
        if (thumbPath != null) {
          setState(() {
            _videoThumbnailFile = File(thumbPath);
          });
        }
      } catch (e) {
        // Thumbnail generation failed, but that's okay
        print('Thumbnail generation failed: $e');
      }
    }
  }

  void _submit() async {
    setState(() {
      _submitting = true;
    });
    // Show progress dialog
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder:
    //       (context) => AlertDialog(
    //         content: Row(
    //           children: [
    //             const CircularProgressIndicator(),
    //             const SizedBox(width: 16),
    //             Expanded(child: Text('Uploading entry...')),
    //           ],
    //         ),
    //       ),
    // );
    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('User not logged in');
      final userId = user.uid;
      final challengeId = widget.challenge.id;
      String? mediaType;
      if (_selectedImage != null) {
        mediaType = 'image';
      } else if (_selectedVideo != null) {
        mediaType = 'video';
      }
      // Use background submission service
      await BackgroundSubmissionService.submitInBackground(
        imageFile: _selectedImage,
        videoFile: _selectedVideo,
        videoThumbnailFile: _videoThumbnailFile,
        caption: _captionController.text.trim(),
        userId: userId,
        challengeId: challengeId,
        mediaType: mediaType,
        context: context,
      );
      setState(() {
        _submitting = false;
      });
      // Old logic (kept as fallback, now commented out):
      /*
      final submissionService = SubmissionService();
      String? mediaUrl;
      String? thumbnailUrl;
      if (_selectedImage != null || _selectedVideo != null) {
        final file = _selectedImage ?? _selectedVideo!;
        mediaUrl = await submissionService.uploadMedia(
          file,
          userId,
          challengeId,
        );
        if (_selectedVideo != null && _videoThumbnailFile != null) {
          thumbnailUrl = await submissionService.uploadThumbnail(
            _videoThumbnailFile!,
            userId,
            challengeId,
          );
        }
      } else {
        mediaUrl = null;
      }
      final submission = Submission(
        id: '',
        challengeId: challengeId,
        userId: userId,
        mediaUrl: mediaUrl,
        caption: _captionController.text.trim(),
        timestamp: Timestamp.now(),
        thumbnailUrl: thumbnailUrl,
        mediaType: mediaType,
      );
      await submissionService.addSubmission(submission);
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entry submitted!')));
      Navigator.pop(context);
      */
    } catch (e) {
      setState(() {
        _submitting = false;
      });
      // Navigator.of(context, rootNavigator: true).pop();
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
      appBar: AppBar(
        title: Text('Submit Entry', style: TextStyle(fontSize: 20.sp)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challenge: ${widget.challenge.title}',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24.h),
              Text(
                'Image',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: _pickImage,
                child:
                    _selectedImage != null
                        ? Image.file(_selectedImage!, height: 150.h)
                        : Container(
                          height: 150.h,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.add_a_photo,
                            size: 40.sp,
                            color: Colors.grey,
                          ),
                        ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Video',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: _pickVideo,
                child:
                    _selectedVideo != null
                        ? Row(
                          children: [
                            Icon(
                              Icons.videocam,
                              size: 40.sp,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(_selectedVideo!.path.split('/').last),
                            ),
                          ],
                        )
                        : Container(
                          height: 60.h,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.add_to_photos,
                            size: 40.sp,
                            color: Colors.grey,
                          ),
                        ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Caption',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _captionController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a caption for your entry',
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child:
                      _submitting
                          ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            'Submit Entry',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

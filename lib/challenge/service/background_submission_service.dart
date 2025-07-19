import 'dart:io';
import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Added for Timestamp
import '../model/submission_model.dart';
import 'submission_service.dart';

class BackgroundSubmissionService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);
  }

  static Future<void> showSuccessNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'submission_channel',
          'Submission Notifications',
          channelDescription: 'Notifies when challenge entry is uploaded',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notifications.show(
      0,
      'Entry Uploaded!',
      'Your challenge entry was uploaded successfully and will appear in the feed soon.',
      platformChannelSpecifics,
    );
  }

  /// Call this from UI. It will spawn an isolate for heavy work.
  static Future<void> submitInBackground({
    required File? imageFile,
    required File? videoFile,
    required File? videoThumbnailFile,
    required String caption,
    required String userId,
    required String challengeId,
    required String? mediaType,
    required BuildContext context,
  }) async {
    // Show immediate feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Your entry is being processed in the background. Please keep the app open and connected to the internet. You’ll get a notification when your upload is complete!',
        ),
        duration: Duration(seconds: 5),
      ),
    );
    Navigator.of(context).pop(); // Go back to previous screen

    // Start background work (not a true isolate for now, but off the UI thread)
    Future(() async {
      try {
        final submissionService = SubmissionService();
        String? mediaUrl;
        String? thumbnailUrl;
        dynamic finalImage = imageFile;
        dynamic finalVideo = videoFile;
        File? finalThumbnail = videoThumbnailFile;

        if (imageFile != null) {
          // Compress image
          final compressed = await FlutterImageCompress.compressAndGetFile(
            imageFile.path,
            '${imageFile.path}_compressed.jpg',
            quality: 70,
          );
          if (compressed != null) {
            if (compressed is File) {
              finalImage = compressed;
            } else if (compressed.runtimeType.toString() == 'XFile') {
              finalImage = File((compressed as dynamic).path);
            } else {
              finalImage = imageFile;
            }
          } else {
            finalImage = imageFile;
          }
        }
        if (videoFile != null) {
          // Compress video
          final info = await VideoCompress.compressVideo(
            videoFile.path,
            quality: VideoQuality.MediumQuality,
            deleteOrigin: false,
            includeAudio: true,
            frameRate: 30,
          );
          finalVideo = info?.file ?? videoFile;
          // Generate thumbnail if not already
          if (videoThumbnailFile == null) {
            final thumbPath = await VideoThumbnail.thumbnailFile(
              video: (finalVideo as File).path,
              thumbnailPath: (await getTemporaryDirectory()).path,
              imageFormat: ImageFormat.PNG,
              maxHeight: 320,
              quality: 75,
            );
            if (thumbPath != null) {
              finalThumbnail = File(thumbPath);
            }
          }
        }
        // Upload media
        final fileToUpload = finalImage ?? finalVideo;
        mediaUrl = await submissionService.uploadMedia(
          fileToUpload as File,
          userId,
          challengeId,
        );
        // Upload thumbnail if video
        if (mediaType == 'video' && finalThumbnail != null) {
          thumbnailUrl = await submissionService.uploadThumbnail(
            finalThumbnail,
            userId,
            challengeId,
          );
        }
        // Create submission
        final submission = Submission(
          id: '',
          challengeId: challengeId,
          userId: userId,
          mediaUrl: mediaUrl,
          caption: caption,
          timestamp: Timestamp.now(),
          thumbnailUrl: thumbnailUrl,
          mediaType: mediaType,
        );
        await submissionService.addSubmission(submission);
        await showSuccessNotification();
      } catch (e) {
        // Optionally, show a failure notification
      }
    });
  }
}

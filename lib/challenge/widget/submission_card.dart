import 'package:flutter/material.dart';
import '../model/submission_model.dart';

class SubmissionCard extends StatelessWidget {
  final Submission submission;
  const SubmissionCard({Key? key, required this.submission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading:
            submission.isVideo
                ? Stack(
                  children: [
                    // Show thumbnail if available, otherwise show a placeholder
                    submission.thumbnailUrl != null &&
                            submission.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                          submission.thumbnailUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  _buildVideoPlaceholder(),
                        )
                        : _buildVideoPlaceholder(),
                    // Play icon overlay
                    const Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                )
                : Image.network(
                  submission.mediaUrl ?? '',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                ),
        title: Text(submission.caption ?? ''),
        subtitle: Text('By: ${submission.userId}'),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[200],
      child: const Icon(Icons.videocam, color: Colors.grey, size: 24),
    );
  }
}

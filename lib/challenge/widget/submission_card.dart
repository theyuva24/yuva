import 'package:flutter/material.dart';
import '../model/submission_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                        ? CachedNetworkImage(
                          imageUrl: submission.thumbnailUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                ),
                              ),
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
                : CachedNetworkImage(
                  imageUrl: submission.mediaUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 48,
                          ),
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

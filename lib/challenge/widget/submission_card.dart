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
                                color: Theme.of(context).dividerColor.withAlpha(51),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Theme.of(context).dividerColor.withAlpha(102),
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                                    size: 48,
                                  ),
                                ),
                              ),
                        )
                        : _buildVideoPlaceholder(context),
                    // Play icon overlay
                    Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Theme.of(context).colorScheme.onPrimary.withAlpha(179),
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
                        color: Theme.of(context).dividerColor.withAlpha(51),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Theme.of(context).dividerColor.withAlpha(102),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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

  Widget _buildVideoPlaceholder(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: Theme.of(context).dividerColor.withAlpha(204),
      child: Icon(
        Icons.videocam,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
        size: 24,
      ),
    );
  }
}

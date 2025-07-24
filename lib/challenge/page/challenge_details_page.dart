import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import 'submit_entry_page.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';
import '../service/submission_service.dart';
import '../model/submission_model.dart';
import 'full_screen_media_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChallengeDetailsPage extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailsPage({Key? key, required this.challenge})
    : super(key: key);

  @override
  State<ChallengeDetailsPage> createState() => _ChallengeDetailsPageState();
}

class _ChallengeDetailsPageState extends State<ChallengeDetailsPage> {
  bool _isExpanded = false;
  static const int _descTrimLength = 120;
  final SubmissionService _submissionService = SubmissionService();

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final now = DateTime.now();
    final endDate =
        DateTime.tryParse(challenge.endDate) ?? challenge.deadline.toDate();
    final startDate = DateTime.tryParse(challenge.startDate) ?? now;
    final totalDuration = endDate.difference(startDate).inSeconds;
    final elapsed =
        now.isBefore(startDate)
            ? 0
            : now.isAfter(endDate)
            ? totalDuration
            : now.difference(startDate).inSeconds;
    final progress =
        totalDuration > 0 ? (elapsed / totalDuration).clamp(0.0, 1.0) : 1.0;

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    String desc = challenge.description;
    bool showReadMore = desc.length > _descTrimLength;
    String displayDesc =
        (!_isExpanded && showReadMore)
            ? desc.substring(0, _descTrimLength) + '...'
            : desc;

    return Scaffold(
      backgroundColor: AppThemeLight.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        centerTitle: true,
        title: Text(
          challenge.title,
          style:
              textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    offset: Offset(0, 0),
                  ),
                ],
              ) ??
              TextStyle(),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.zero, // remove extra bottom space
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge image at the top
                  CachedNetworkImage(
                    imageUrl: challenge.imageUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Theme.of(context).dividerColor,
                          width: double.infinity,
                          height: 220,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Theme.of(context).dividerColor,
                          width: double.infinity,
                          height: 220,
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar for end date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress < 1.0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Start: ${_formatDate(startDate)}',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: AppThemeLight.primary,
                              ),
                            ),
                            Text(
                              'End: ${_formatDate(endDate)}',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: AppThemeLight.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Card with description and info boxes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppThemeLight.primary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeLight.primary.withAlpha(15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description and Read More inline
                          RichText(
                            text: TextSpan(
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                color: AppThemeLight.textPrimary,
                              ),
                              children: [
                                TextSpan(text: displayDesc),
                                if (showReadMore)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isExpanded = !_isExpanded;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          _isExpanded
                                              ? 'Read Less'
                                              : 'Read More',
                                          style: textTheme.labelLarge?.copyWith(
                                            color: AppThemeLight.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _InfoBox(
                                  label: 'Post Type',
                                  value:
                                      challenge.postType.isNotEmpty
                                          ? (challenge.postType[0]
                                                  .toUpperCase() +
                                              challenge.postType.substring(1))
                                          : '',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _InfoBox(
                                  label: 'Prize',
                                  value: challenge.prize,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Submitted entries grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FutureBuilder<List<Submission>>(
                      future: _submissionService.fetchSubmissionsForChallenge(
                        challenge.id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading submissions: ${snapshot.error}',
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No submissions found.'),
                          );
                        }
                        final submissions =
                            snapshot.data!
                                .where(
                                  (s) =>
                                      s.mediaUrl != null &&
                                      s.mediaUrl!.isNotEmpty,
                                )
                                .toList();
                        // Debug print
                        print(
                          'Fetched submissions: ${submissions.map((s) => s.mediaUrl).toList()}',
                        );
                        if (submissions.isEmpty) {
                          return const Center(
                            child: Text('No images found for this challenge.'),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submitted Entries',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppThemeLight.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: submissions.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                              itemBuilder: (context, index) {
                                final submission = submissions[index];
                                // Prefetch next 3 images/thumbnails
                                for (int i = 1; i <= 3; i++) {
                                  if (index + i < submissions.length) {
                                    final next = submissions[index + i];
                                    if (next.isVideo &&
                                        next.thumbnailUrl != null &&
                                        next.thumbnailUrl!.isNotEmpty) {
                                      CachedNetworkImageProvider(
                                        next.thumbnailUrl!,
                                      ).resolve(const ImageConfiguration());
                                    } else if (!next.isVideo &&
                                        next.mediaUrl != null &&
                                        next.mediaUrl!.isNotEmpty) {
                                      CachedNetworkImageProvider(
                                        next.mediaUrl!,
                                      ).resolve(const ImageConfiguration());
                                    }
                                  }
                                }
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => FullScreenMediaPage(
                                              submissions: submissions,
                                              initialIndex: index,
                                            ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        submission.isVideo
                                            ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                // Show thumbnail if available, otherwise show a placeholder
                                                submission.thumbnailUrl !=
                                                            null &&
                                                        submission
                                                            .thumbnailUrl!
                                                            .isNotEmpty
                                                    ? CachedNetworkImage(
                                                      imageUrl:
                                                          submission
                                                              .thumbnailUrl!,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => Container(
                                                            color:
                                                                Theme.of(
                                                                  context,
                                                                ).dividerColor,
                                                            child: const Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) =>
                                                              _buildVideoPlaceholder(
                                                                context,
                                                              ),
                                                    )
                                                    : _buildVideoPlaceholder(
                                                      context,
                                                    ),
                                                // Play icon overlay
                                                Center(
                                                  child: Icon(
                                                    Icons.play_circle_fill,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary
                                                        .withOpacity(0.7),
                                                    size: 48,
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
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).dividerColor,
                                                    width: double.infinity,
                                                    height: 180,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).dividerColor,
                                                    width: double.infinity,
                                                    height: 180,
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.6),
                                                        size: 48,
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmitEntryPage(challenge: challenge),
            ),
          );
        },
        backgroundColor: AppThemeLight.primary,
        icon: Icon(
          Icons.emoji_events,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        label: Text(
          'Take Part',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

String _formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

Widget _buildVideoPlaceholder(BuildContext context) {
  return Container(
    color: Theme.of(context).colorScheme.surface,
    child: Icon(
      Icons.videocam,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      size: 40,
    ),
  );
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeLight.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppThemeLight.primary.withAlpha(10),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label + ': ',
            style: TextStyle(
              fontSize: 15,
              color: AppThemeLight.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppThemeLight.textPrimary,
              ),
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

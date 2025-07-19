import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import 'submit_entry_page.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';
import '../service/submission_service.dart';
import '../model/submission_model.dart';
import 'full_screen_media_page.dart';

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
        backgroundColor: AppThemeLight.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppThemeLight.primary),
        centerTitle: true,
        title: Text(
          challenge.title,
          style: GoogleFonts.orbitron(
            textStyle:
                textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppThemeLight.primary,
                  letterSpacing: 2,
                  shadows: const [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black12,
                      offset: Offset(0, 0),
                    ),
                  ],
                ) ??
                const TextStyle(),
          ),
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
                  Image.network(
                    challenge.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                          backgroundColor: AppThemeLight.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress < 1.0
                                ? AppThemeLight.primary
                                : Colors.redAccent,
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
                        color: AppThemeLight.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppThemeLight.primary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeLight.primary.withOpacity(0.06),
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
                                color: AppThemeLight.textDark,
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
                                                    ? Image.network(
                                                      submission.thumbnailUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) =>
                                                              _buildVideoPlaceholder(),
                                                    )
                                                    : _buildVideoPlaceholder(),
                                                // Play icon overlay
                                                const Center(
                                                  child: Icon(
                                                    Icons.play_circle_fill,
                                                    color: Colors.white70,
                                                    size: 48,
                                                  ),
                                                ),
                                              ],
                                            )
                                            : Image.network(
                                              submission.mediaUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
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
        icon: const Icon(Icons.emoji_events, color: Colors.white),
        label: const Text(
          'Take Part',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
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

Widget _buildVideoPlaceholder() {
  return Container(
    color: Colors.grey[200],
    child: const Icon(Icons.videocam, color: Colors.grey, size: 40),
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
        color: AppThemeLight.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeLight.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppThemeLight.primary.withOpacity(0.04),
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
            style: const TextStyle(
              fontSize: 15,
              color: AppThemeLight.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppThemeLight.textDark,
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

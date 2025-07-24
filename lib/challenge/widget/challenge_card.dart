import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import '../page/challenge_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  const ChallengeCard({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeDetailsPage(challenge: challenge),
          ),
        );
      },
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.12),
              blurRadius: 12,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top 75%: Image
              Expanded(
                flex: 75,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: challenge.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                  size: 48,
                                ),
                              ),
                            ),
                      ),
                    ),
                    // Prize badge
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _PrizeBadge(prize: challenge.prize),
                    ),
                    // Days left badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _DaysLeftBadge(challenge: challenge),
                    ),
                  ],
                ),
              ),
              // Minimalist pill progress bar, flush with card edges
              _ChallengeTimingBarMinimal(challenge: challenge),
              // Bottom text area (reduce flex to compensate for bar)
              Expanded(
                flex: 25,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    challenge.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _ChallengeTimingBar extends StatelessWidget {
  final Challenge challenge;
  const _ChallengeTimingBar({required this.challenge});

  @override
  Widget build(BuildContext context) {
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 10,
        backgroundColor: Theme.of(context).colorScheme.surface,
        valueColor: AlwaysStoppedAnimation<Color>(
          progress < 1.0
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _DaysLeftBadge extends StatelessWidget {
  final Challenge challenge;
  const _DaysLeftBadge({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final endDate =
        DateTime.tryParse(challenge.endDate) ?? challenge.deadline.toDate();
    final daysLeft = endDate.difference(now).inDays;
    final text =
        daysLeft > 0
            ? '$daysLeft days left'
            : (daysLeft == 0 ? 'Last day' : 'Closed');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(0),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PrizeBadge extends StatelessWidget {
  final String prize;
  const _PrizeBadge({required this.prize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text(
        'Win ₹$prize',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// Minimalist pill version of the timing bar below the image
class _ChallengeTimingBarMinimal extends StatelessWidget {
  final Challenge challenge;
  const _ChallengeTimingBarMinimal({required this.challenge});

  @override
  Widget build(BuildContext context) {
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 7,
          backgroundColor: Theme.of(context).colorScheme.surface,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress < 1.0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}

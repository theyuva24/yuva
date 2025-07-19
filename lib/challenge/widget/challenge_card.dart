import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import '../page/challenge_details_page.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  const ChallengeCard({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deadline = challenge.deadline.toDate();
    final now = DateTime.now();
    final daysLeft = deadline.difference(now).inDays;
    final isExpired = deadline.isBefore(now);
    final dateStr = DateFormat('MMM d, yyyy').format(deadline);

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
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppThemeLight.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppThemeLight.primary.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Challenge image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                challenge.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
              ),
            ),
            // Content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      challenge.title,
                      style: GoogleFonts.orbitron(
                        textStyle: const TextStyle(
                          color: AppThemeLight.textDark, // Use theme dark text
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        color: AppThemeLight.textDark, // Use theme dark text
                        fontSize: 15,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: AppThemeLight.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          challenge.prize,
                          style: const TextStyle(
                            color: AppThemeLight.primary, // Use theme primary
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.timer,
                          color: AppThemeLight.accent, // Use accent for timer
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpired
                              ? 'Closed'
                              : daysLeft > 0
                              ? '$daysLeft days left'
                              : 'Last day',
                          style: TextStyle(
                            color:
                                AppThemeLight
                                    .accent, // Use accent for timer text
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Removed View/Join button
                        const Spacer(),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color:
                                AppThemeLight
                                    .textLight, // Use theme light text for date
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

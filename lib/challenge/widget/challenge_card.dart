import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import '../page/challenge_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';
import 'package:intl/intl.dart';

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
        height: 250,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
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
              // Fixed-height timing bar
              SizedBox(
                height: 10,
                child: _ChallengeTimingBar(challenge: challenge),
              ),
              // Bottom text area (reduce flex to compensate for bar)
              Expanded(
                flex: 15,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    challenge.title,
                    style: GoogleFonts.orbitron(
                      textStyle: const TextStyle(
                        color: AppThemeLight.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
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

    return LinearProgressIndicator(
      value: progress,
      minHeight: 10,
      backgroundColor: const Color(0xFFF3E8FF), // light purple
      valueColor: AlwaysStoppedAnimation<Color>(
        progress < 1.0
            ? const Color(0xFF7C3AED)
            : Colors.redAccent, // dark purple
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
      decoration: const BoxDecoration(
        color: Color(0xFFF3E8FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(0),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
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
      decoration: const BoxDecoration(
        color: Color(0xFFF3E8FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text(
        'Win ₹$prize',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

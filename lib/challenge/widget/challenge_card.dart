import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import '../page/challenge_details_page.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
          border: Border.all(color: Color(0xFF00F6FF), width: 2),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF00F6FF).withOpacity(0.25),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 0),
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
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF181C23).withOpacity(0.85),
                  ],
                  stops: const [0.5, 1.0],
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
                          color: Color(0xFF00F6FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(color: Color(0xFF00F6FF), blurRadius: 12),
                            Shadow(color: Colors.black26, blurRadius: 4),
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
                        color: Colors.white70,
                        fontSize: 15,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Color(0xFF00F6FF),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          challenge.prize,
                          style: const TextStyle(
                            color: Color(0xFF00F6FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.timer, color: Color(0xFF00F6FF), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          isExpired
                              ? 'Closed'
                              : daysLeft > 0
                              ? '$daysLeft days left'
                              : 'Last day',
                          style: TextStyle(
                            color:
                                isExpired ? Colors.red[200] : Color(0xFF00F6FF),
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
                            color: Colors.white70,
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

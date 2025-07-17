import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import 'submit_entry_page.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/gradient_button.dart';

class ChallengeDetailsPage extends StatelessWidget {
  final Challenge challenge;
  const ChallengeDetailsPage({Key? key, required this.challenge})
    : super(key: key);

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

    return Scaffold(
      backgroundColor: const Color(0xFF181C23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181C23),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F6FF)),
        title: Text(
          challenge.title,
          style: GoogleFonts.orbitron(
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F6FF),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  blurRadius: 16,
                  color: Color(0xFF00F6FF),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
            // Challenge name/title
            // (Title is now in AppBar)
            const SizedBox(height: 8),
            // Progress bar for end date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress < 1.0 ? Color(0xFF00F6FF) : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start: ${_formatDate(startDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00F6FF),
                        ),
                      ),
                      Text(
                        'End: ${_formatDate(endDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00F6FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Card with description and 3 boxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF232733),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF00F6FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00F6FF).withOpacity(0.12),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.description,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoBox(label: 'Post Type', value: challenge.postType),
                        _InfoBox(label: 'Prize', value: challenge.prize),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Optionally, add more details below
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GradientButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SubmitEntryPage(challenge: challenge),
                    ),
                  );
                },
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: const Text(
                  'Submit Entry',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF181C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF00F6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00F6FF).withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF00F6FF),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

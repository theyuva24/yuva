import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import 'submit_entry_page.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';

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
      backgroundColor: AppThemeLight.background,
      appBar: AppBar(
        backgroundColor: AppThemeLight.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppThemeLight.primary),
        title: Text(
          challenge.title,
          style: GoogleFonts.orbitron(
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppThemeLight.primary,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black12,
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
                    backgroundColor: AppThemeLight.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress < 1.0 ? AppThemeLight.primary : Colors.redAccent,
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
                          color: AppThemeLight.primary,
                        ),
                      ),
                      Text(
                        'End: ${_formatDate(endDate)}',
                        style: const TextStyle(
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
            // Card with description and 3 boxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppThemeLight.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppThemeLight.primary, width: 2),
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
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppThemeLight.textDark,
                      ),
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
                text: 'Submit Entry',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SubmitEntryPage(challenge: challenge),
                    ),
                  );
                },
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
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppThemeLight.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppThemeLight.textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

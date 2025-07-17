import 'package:flutter/material.dart';
import 'package:yuva/universal/theme/neon_theme.dart';

class InterestsSection extends StatelessWidget {
  final List<String> interests;
  const InterestsSection({Key? key, required this.interests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children:
          interests
              .map(
                (interest) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: NeonColors.neonCyan, width: 1.5),
                    color: Colors.transparent,
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: NeonColors.neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

import 'package:flutter/material.dart';
import '../../universal/theme/app_theme.dart';

class InterestsCard extends StatelessWidget {
  final List<String> interests;
  const InterestsCard({Key? key, required this.interests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppThemeLight.surface,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppThemeLight.primary, width: 1.5),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          children:
              interests
                  .map(
                    (interest) => Chip(
                      label: Text(
                        interest,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppThemeLight.primary.withOpacity(0.15),
                      labelStyle: const TextStyle(color: AppThemeLight.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(
                          color: AppThemeLight.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

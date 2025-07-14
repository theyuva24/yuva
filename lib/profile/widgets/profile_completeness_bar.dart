import 'package:flutter/material.dart';

class ProfileCompletenessBar extends StatelessWidget {
  final double completeness;
  const ProfileCompletenessBar({Key? key, required this.completeness})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF181C23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFF00F6FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00F6FF).withOpacity(0.12),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: completeness,
              backgroundColor: const Color(0xFF232A34),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F6FF)),
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(completeness * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Color(0xFF00F6FF),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [
                Shadow(
                  blurRadius: 6,
                  color: Color(0xFF00F6FF),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

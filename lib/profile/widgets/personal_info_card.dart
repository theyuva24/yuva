import 'package:flutter/material.dart';

class PersonalInfoCard extends StatelessWidget {
  final DateTime? dob;
  final String gender;
  final String contact;
  const PersonalInfoCard({
    Key? key,
    this.dob,
    required this.gender,
    required this.contact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF181C23),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF00F6FF), width: 1.5),
      ),
      elevation: 6,
      shadowColor: Color(0xFF00F6FF).withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                color: Color(0xFF00F6FF),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Color(0xFF00F6FF),
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.cake, color: Color(0xFF00F6FF)),
              title: Text(
                'Date of Birth',
                style: TextStyle(color: Colors.grey[300]),
              ),
              subtitle: Text(
                dob != null
                    ? '${dob!.day}/${dob!.month}/${dob!.year}'
                    : 'Not set',
                style: TextStyle(
                  color: Color(0xFF00F6FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: Color(0xFF00F6FF)),
              title: Text('Gender', style: TextStyle(color: Colors.grey[300])),
              subtitle: Text(
                gender.isNotEmpty ? gender : 'Not set',
                style: TextStyle(
                  color: Color(0xFF00F6FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Color(0xFF00F6FF)),
              title: Text('Contact', style: TextStyle(color: Colors.grey[300])),
              subtitle: Text(
                contact.isNotEmpty ? contact : 'Not set',
                style: TextStyle(
                  color: Color(0xFF00F6FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.cake),
              title: Text('Date of Birth'),
              subtitle: Text(
                dob != null
                    ? '${dob!.day}/${dob!.month}/${dob!.year}'
                    : 'Not set',
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Gender'),
              subtitle: Text(gender.isNotEmpty ? gender : 'Not set'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Contact'),
              subtitle: Text(contact.isNotEmpty ? contact : 'Not set'),
            ),
          ],
        ),
      ),
    );
  }
}

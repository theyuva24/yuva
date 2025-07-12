import 'package:flutter/material.dart';

class VerificationStatusCard extends StatelessWidget {
  final bool idVerified;
  final String location;
  const VerificationStatusCard({
    Key? key,
    required this.idVerified,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              idVerified ? Icons.verified : Icons.verified_outlined,
              color: idVerified ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(idVerified ? 'ID Verified' : 'ID Not Verified'),
            const Spacer(),
            Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 4),
            Text(location),
          ],
        ),
      ),
    );
  }
}

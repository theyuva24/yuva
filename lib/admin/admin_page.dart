import 'package:flutter/material.dart';
import '../connect/pages/hubs_page.dart';
import 'hub_admin_page.dart';
import 'challenge_admin_page.dart';

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => HubAdminPage()));
              },
              child: Text('Create Hub'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ChallengeAdminPage()),
                );
              },
              child: Text('Create Challenge'),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../admin/admin_page.dart';
import '../initial pages/auth_service.dart';
import '../profile/models/profile_model.dart';
import 'package:share_plus/share_plus.dart';
import '../initial pages/presentation/screens/onboarding_screen.dart';

class SettingsPage extends StatelessWidget {
  final ProfileModel profile;
  const SettingsPage({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile.phone == '9876543210';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0A0E17),
      ),
      backgroundColor: const Color(0xFF0A0E17),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text(
              'About Yuva',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('About Yuva'),
                      content: const Text(
                        'Yuva is a modern learning platform.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.white),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Privacy Policy'),
                      content: const Text('Privacy policy details go here.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text(
              'Share App',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Share.share('Check out Yuva app!');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
              if (shouldLogout == true) {
                await AuthService().signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
              ),
              title: const Text('Admin', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => AdminPage()));
              },
            ),
        ],
      ),
    );
  }
}

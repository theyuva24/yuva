import 'package:flutter/material.dart';
import '../admin/admin_page.dart';
import '../initial pages/auth_service.dart';
import '../profile/models/profile_model.dart';
import 'package:share_plus/share_plus.dart';
import '../initial pages/presentation/screens/onboarding_screen.dart';
import 'package:yuva/universal/theme/app_theme.dart';
import 'privacy_policy_page.dart';
import 'terms_and_conditions_page.dart';
import 'about_yuva_page.dart';

class SettingsPage extends StatelessWidget {
  final ProfileModel profile;
  const SettingsPage({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile.phone
        .replaceAll(RegExp(r'\D'), '')
        .endsWith('9876543210');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              Icons.info,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              'About Yuva',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutYuvaPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.privacy_tip,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              'Privacy Policy',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.article,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              'Terms & Conditions',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsAndConditionsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.share,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: const Text(
              'Share App',
              style: TextStyle(color: null), // Remove static color
            ),
            onTap: () {
              Share.share('Check out Yuva app!');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: null), // Remove static color
            ),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: null), // Remove static color
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: null), // Remove static color
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
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
                color: AppThemeLight.textPrimary,
              ),
              title: const Text(
                'Admin',
                style: TextStyle(color: AppThemeLight.textPrimary),
              ),
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

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
        title: const Text(
          'Settings',
          style: TextStyle(color: AppThemeLight.textDark),
        ),
        backgroundColor: AppThemeLight.surface,
        iconTheme: const IconThemeData(color: AppThemeLight.textDark),
      ),
      backgroundColor: AppThemeLight.background,
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: AppThemeLight.textDark),
            title: const Text(
              'About Yuva',
              style: TextStyle(color: AppThemeLight.textDark),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutYuvaPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.privacy_tip,
              color: AppThemeLight.textDark,
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(color: AppThemeLight.textDark),
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
            leading: const Icon(Icons.article, color: AppThemeLight.textDark),
            title: const Text(
              'Terms & Conditions',
              style: TextStyle(color: AppThemeLight.textDark),
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
            leading: const Icon(Icons.share, color: AppThemeLight.textDark),
            title: const Text(
              'Share App',
              style: TextStyle(color: AppThemeLight.textDark),
            ),
            onTap: () {
              Share.share('Check out Yuva app!');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppThemeLight.textDark),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppThemeLight.textDark),
            ),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: AppThemeLight.textDark),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: AppThemeLight.textDark),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppThemeLight.primary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: AppThemeLight.primary),
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
                color: AppThemeLight.textDark,
              ),
              title: const Text(
                'Admin',
                style: TextStyle(color: AppThemeLight.textDark),
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

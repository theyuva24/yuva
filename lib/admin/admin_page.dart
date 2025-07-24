import 'package:flutter/material.dart';
import '../connect/pages/hubs_page.dart';
import 'hub_admin_page.dart';
import 'challenge_admin_page.dart';
import 'college_admin_page.dart';
import '../universal/theme/app_theme.dart';

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).brightness == Brightness.dark
          ? AppThemeDark.theme
          : AppThemeLight.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
          titleTextStyle: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => HubAdminPage()),
                  );
                },
                child: const Text('Create Hub'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ChallengeAdminPage()),
                  );
                },
                child: const Text('Create Challenge'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CollegeAdminPage()),
                  );
                },
                child: const Text('Manage Colleges'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

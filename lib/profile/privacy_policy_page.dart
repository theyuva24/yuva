import 'package:flutter/material.dart';
import 'package:yuva/universal/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YUVA App Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Last Updated: July 22, 2025',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'YUVA Tech Pvt. Ltd. ("YUVA", "we", "us", "our") values your privacy. This Privacy Policy explains how we collect, use, disclose, and protect your personal information when you use the YUVA mobile application ("App"). By accessing or using the App, you agree to the terms of this Privacy Policy.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '1. Information We Collect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '1.1. Account Information. When you register, we collect your name, email address, phone number, date of birth, and any profile details you choose to provide (e.g., photo, bio).',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1.2. Usage Data. We automatically collect data about how you interact with the App, including pages visited, features used, timestamps, device identifiers, IP addresses, and crash reports.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1.3. Content You Create. Any text, images, videos, or other materials you post or upload as part of your profile, comments, posts, challenges, or messages.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1.4. Device & Location Data. Information about your device (e.g., model, operating system) and, with your permission, approximate location.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1.5. Cookies & Similar Technologies. We use cookies, SDKs, and similar tools to recognize your device, personalize content, and analyze usage.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '2. How We Use Your Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '• Provide & Improve Services. Operate the App, deliver features, troubleshoot issues, and develop new functionalities.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Personalize Experience. Tailor content, recommendations, and notifications based on your preferences and activity.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Communicate. Send account confirmations, updates, security alerts, and marketing messages (with your consent).',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Analytics & Research. Understand usage patterns, measure effectiveness of campaigns, and optimize performance.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Security & Compliance. Detect fraud, enforce Terms, and comply with legal obligations.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '3. Sharing & Disclosure',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'We may share your information with:',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Service Providers. Trusted third parties who perform services on our behalf (e.g., hosting, analytics, support).',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Business Transfers. In connection with a merger, acquisition, or sale of assets, with notice to you.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Legal Requirements. When required by law or to protect rights, safety, or property of YUVA, you, or others.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Public Content. Information you choose to make public, such as posts or profile details visible to other users.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'We do not sell or rent your personal information to unaffiliated third parties for marketing purposes.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '4. Your Choices & Rights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '• Access & Correction. You can view or update account information via App settings.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Data Portability. Request a copy of your data in a standard format.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Deletion. Delete your account at any time; we will remove personal data except as required to comply with law or legitimate business purposes.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Marketing Opt-Out. Unsubscribe from promotional emails by following the link in those communications.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '• Cookie Settings. Manage cookie preferences via your device or browser settings.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'To exercise these rights, contact us at privacy@yuvaapp.com.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '5. Data Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'We implement industry-standard measures to protect your data, including encryption in transit (TLS) and at rest, secure authentication, and regular audits. However, no method is entirely secure; please use unique, strong passwords.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '6. Data Retention',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'We retain personal data only as long as necessary to provide services, comply with legal obligations, resolve disputes, and enforce agreements. Usage data may be kept for up to 24 months in aggregated or anonymized form.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '7. Children’s Privacy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Our App is not directed to children under 16 (or the age of majority in your jurisdiction). We do not knowingly collect personal information from minors. If we learn that we have collected such data, we will promptly delete it.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '8. International Transfer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your information may be transferred to and processed in India and other countries. We ensure adequate safeguards are in place to protect your privacy in accordance with applicable law.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '9. Changes to This Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'We may update this Privacy Policy periodically. We will notify you of material changes via in-App notices or email and update the "Last Updated" date. Continued use after changes indicates acceptance.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20),
              Text(
                '10. Contact Us',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'If you have any questions or requests regarding this Privacy Policy, please contact:',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'YUVA Tech Pvt. Ltd.\nEmail: privacy@yuvaapp.com\nAddress: 123 Tech Park Road, Bengaluru, Karnataka, India',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Thank you for trusting YUVA with your information.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

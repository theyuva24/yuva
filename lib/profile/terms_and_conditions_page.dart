import 'package:flutter/material.dart';
import 'package:yuva/universal/theme/app_theme.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeLight.background,
      appBar: AppBar(
        backgroundColor: AppThemeLight.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Terms and Conditions for the YUVA App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Last Updated: July 22, 2025',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '1. Definitions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '1.1. "Content" means any text, images, videos, audio, graphics, or other material uploaded, posted, or otherwise made available through the App.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '1.2. "User Content" means any Content submitted or uploaded by Users.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '1.3. "Services" refers to any features, functionalities, or tools offered through the App.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '2. Acceptance of Terms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '2.1. By creating an account or using the App, you confirm that you are at least 16 years old (or the age of majority in your jurisdiction) and have full legal capacity to enter into these Terms.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '2.2. You agree to comply with all applicable local, state, national, and international laws and regulations when using the App.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '3. Account Registration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '3.1. To access certain features, you must register for an account. You agree to provide accurate, current, and complete information during registration and to keep your account information updated.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '3.2. You are solely responsible for safeguarding your password and any activities that occur under your account. Immediately notify us of any unauthorized use.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '4. License and Restrictions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '4.1. YUVA grants you a limited, non-exclusive, non-transferable, revocable license to use the App for your personal, non-commercial use, subject to these Terms.',
                style: TextStyle(fontSize: 16),
              ),
              Text('4.2. You shall not:', style: TextStyle(fontSize: 16)),
              Text(
                'a. Copy, modify, reverse engineer, or create derivative works of the App.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'b. Rent, lease, distribute, sell, or sublicense any part of the App.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'c. Remove any proprietary notices.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'd. Interfere with or disrupt the integrity or performance of the App.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '5. User Content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '5.1. You retain ownership of any User Content you post, upload, or otherwise make available. By submitting User Content, you grant YUVA a worldwide, royalty-free, perpetual, irrevocable, sublicensable, transferable license to use, reproduce, distribute, prepare derivative works, and display such Content in connection with the App.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '5.2. You represent and warrant that you own or control all rights to your User Content and that posting it does not violate any third party rights.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '6. Prohibited Conduct',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'You agree not to use the App to:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Post or transmit unlawful, harassing, defamatory, obscene, or otherwise objectionable Content.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Harass, threaten, or defame any person.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Impersonate any person or entity.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Upload viruses, malicious code, or any harmful software.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Collect or store personal information about other Users without their consent.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Engage in any fraudulent activity.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '7. Privacy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Our Privacy Policy governs the collection, use, and disclosure of your personal information. By using the App, you consent to our collection and use of information as outlined in that policy.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '8. Third-Party Links and Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'The App may contain links to third-party websites, applications, or services. YUVA does not endorse and is not responsible for the content, policies, or practices of any third party.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '9. Disclaimers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '9.1. "AS IS": The App and Services are provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind. YUVA expressly disclaims all warranties, whether express, implied, statutory, or otherwise.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '9.2. No Guarantee: YUVA does not guarantee that the App will be uninterrupted, error-free, or secure.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '10. Limitation of Liability',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'To the maximum extent permitted by law, YUVA and its affiliates, officers, directors, employees, and agents shall not be liable for:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Any indirect, incidental, special, consequential, or punitive damages.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Loss of profits, revenue, data, or goodwill.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Any damages arising from your use of, or inability to use, the App.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'In jurisdictions that do not allow the exclusion or limitation of liability for consequential or incidental damages, YUVA\'s liability shall be limited to the fullest extent permitted by law.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '11. Indemnification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'You agree to defend, indemnify, and hold harmless YUVA, its officers, directors, employees, and agents from any claims, liabilities, losses, and expenses (including reasonable attorneys’ fees) arising out of or relating to:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Your breach of these Terms.',
                style: TextStyle(fontSize: 16),
              ),
              Text('• Your User Content.', style: TextStyle(fontSize: 16)),
              Text(
                '• Your violation of any applicable law.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '12. Termination',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '12.1. We may suspend or terminate your account and access to the App at any time, with or without cause, and with or without notice.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '12.2. Upon termination, all licenses granted to you will immediately cease, and you must cease all use of the App.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '13. Changes to Terms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'YUVA reserves the right to modify these Terms at any time. We will provide notice of changes by updating the "Last Updated" date or through in-App notifications. Continued use of the App after changes become effective constitutes acceptance of the new Terms.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '14. Governing Law and Dispute Resolution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '14.1. These Terms shall be governed by the laws of India, without regard to conflict of law principles.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '14.2. Any dispute arising out of or in connection with these Terms shall be resolved by arbitration in Bengaluru, India, under the Arbitration and Conciliation Act, 1996.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                '15. Miscellaneous',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '15.1. Severability: If any provision of these Terms is found to be invalid or unenforceable, the remaining provisions will remain in full force and effect.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '15.2. Entire Agreement: These Terms, together with our Privacy Policy, constitute the entire agreement between you and YUVA regarding the App.',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '15.3. Waiver: No waiver of any provision shall be deemed a further or continuing waiver.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text(
                'Contact Us',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'If you have questions or concerns about these Terms, please contact us at:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'YUVA Tech Pvt. Ltd.\nEmail: support@yuvaapp.com\nAddress: 123 Tech Park Road, Bengaluru, Karnataka, India',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Thank you for choosing YUVA!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

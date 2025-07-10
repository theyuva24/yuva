import 'package:flutter/material.dart';
import '../widgets/otp_form.dart';

class OTPScreen extends StatelessWidget {
  final String phone;
  const OTPScreen({Key? key, required this.phone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code sent to +91 $phone',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const OTPForm(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Resend OTP
              },
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}

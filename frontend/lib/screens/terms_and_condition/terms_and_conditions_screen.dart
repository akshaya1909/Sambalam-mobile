import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Use',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: February 2026',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Divider(height: 32),
            _sectionTitle('1. Acceptance of Terms'),
            _sectionBody(
              'By accessing and using this application, you agree to be bound by these Terms and Conditions. If you do not agree, please refrain from using our services.',
            ),
            _sectionTitle('2. User Responsibility'),
            _sectionBody(
              'As an admin or employee, you are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account.',
            ),
            _sectionTitle('3. Privacy & Data'),
            _sectionBody(
              'We collect attendance data, location (if enabled), and basic profile details to provide payroll and tracking services. Your data is handled according to our Privacy Policy.',
            ),
            _sectionTitle('4. Subscription & Payments'),
            _sectionBody(
              'Premium features require an active subscription. Failure to renew may result in limited access to advanced reports and CRM tools.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 Sambalam. All rights reserved.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _sectionBody(String content) {
    return Text(
      content,
      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
    );
  }
}

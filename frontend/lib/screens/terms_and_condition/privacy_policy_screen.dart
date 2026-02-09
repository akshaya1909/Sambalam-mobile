import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Our Commitment to Privacy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: February 2026',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Divider(height: 32),
            _sectionTitle('1. Information We Collect'),
            _sectionBody(
              'We collect information to provide better services to our users. This includes profile details (name, phone number), employment info, and attendance records.',
            ),
            _sectionTitle('2. Location Data'),
            _sectionBody(
              'If your company enables GPS attendance, we collect your location coordinates only at the moment you punch in or out. We do not track your movement in the background.',
            ),
            _sectionTitle('3. How We Use Data'),
            _sectionBody(
              'Your data is used to generate accurate payroll reports, track attendance logs, and send automated WhatsApp or app alerts to your employer.',
            ),
            _sectionTitle('4. Data Security'),
            _sectionBody(
              'We implement industry-standard encryption to protect your data from unauthorized access. Your personal information is never sold to third-party advertisers.',
            ),
            _sectionTitle('5. Your Rights'),
            _sectionBody(
              'You have the right to request access to your data or ask for account deletion through your company administrator or by contacting our support.',
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Contact us at: support@sambalam.com',
                style: TextStyle(
                    color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600),
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

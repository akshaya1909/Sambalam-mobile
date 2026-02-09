import 'package:flutter/material.dart';

class DevicePendingScreen extends StatelessWidget {
  const DevicePendingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phonelink_lock_rounded,
                size: 100,
                color: Color(0xFF206C5E),
              ),
              const SizedBox(height: 32),
              const Text(
                'Approval Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You are trying to login from a new device. For security, your Administrator must verify this phone before you can mark attendance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to the very beginning (Login/Phone entry)
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF206C5E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Optional: Refresh button logic or contact support
                },
                child: const Text(
                  'Contact Support',
                  style: TextStyle(color: Color(0xFF206C5E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

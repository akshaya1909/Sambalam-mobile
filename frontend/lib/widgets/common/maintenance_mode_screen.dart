import 'package:flutter/material.dart';

class MaintenanceModeScreen extends StatelessWidget {
  const MaintenanceModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // PopScope prevents the user from using the back button to exit the screen
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Matching web app Slate-900
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated or static icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Color(0xFF1769AA),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'System Maintenance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We are currently updating Sambalam to serve you better. We will be back online shortly. Thank you for your patience!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Visual indicator that it's a restricted state
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Expected back soon',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

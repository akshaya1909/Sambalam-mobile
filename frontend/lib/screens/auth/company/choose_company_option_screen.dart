import 'package:flutter/material.dart';
import '../company/enter_company_screen.dart';
import '../company/create_company_screen.dart';

class ChooseCompanyOptionScreen extends StatelessWidget {
  final String phoneNumber;

  // Primary Gradient Colors
  final Color _primaryStart = const Color(0xFF206C5E);
  final Color _primaryEnd = const Color(0xFF2BA98A);

  const ChooseCompanyOptionScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get constraints for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(
          horizontal: 20), // Prevents touching screen edges
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400, // Maximum width for tablet screens
        ),
        child: SingleChildScrollView(
          // Prevents pixel breakage/overflow on small screens
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Company Setup',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Do you want to join an existing company or create a new one?',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Join Company Button with Gradient
                _buildGradientButton(
                  context: context,
                  label: 'Join Existing Company',
                  icon: Icons.login,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => EnterCompanyScreen(
                          phoneNumber: phoneNumber,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Create Company Button (Outlined style using Primary color)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateCompanyScreen(phoneNumber: phoneNumber),
                      ),
                    );
                  },
                  icon: Icon(Icons.business, color: _primaryStart),
                  label: Text(
                    'Create New Company',
                    style: TextStyle(
                        color: _primaryStart, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: _primaryStart, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build a Responsive Gradient Button
  Widget _buildGradientButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryStart, _primaryEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryStart.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CRMScreen extends StatelessWidget {
  const CRMScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Theme colors matching your app
    final Color primaryDeepTeal = const Color(0xFF206C5E);
    final Color secondaryTeal = const Color(0xFF2BA98A);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDeepTeal, secondaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "CRM",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with decorative background
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: secondaryTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    Icons.handshake_rounded,
                    size: 80,
                    color: primaryDeepTeal,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Main Heading
              const Text(
                "Coming Soon!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937), // Dark grey
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                "Our CRM (Customer Relationship Management) module is currently under development to help you manage clients better.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Feature Tags
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureChip("Lead Tracking"),
                  _buildFeatureChip("Client History"),
                  _buildFeatureChip("Follow-ups"),
                ],
              ),
              const SizedBox(height: 60),
              // Back Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [primaryDeepTeal, secondaryTeal]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "GO BACK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2BA98A).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF206C5E),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

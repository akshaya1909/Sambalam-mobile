import 'package:flutter/material.dart';
import '../screens/subscription/upgrade_pro_screen.dart';

class ExpiredPlanOverlay extends StatelessWidget {
  final bool isOpen;
  final String planName;
  final VoidCallback onRenew;

  const ExpiredPlanOverlay({
    Key? key,
    required this.isOpen,
    required this.planName,
    required this.onRenew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Modal Barrier to prevent interaction with the background
        ModalBarrier(
          dismissible: false,
          color: Colors.black.withOpacity(0.5),
        ),
        Center(
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Red Alert Circle Icon
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline,
                        color: Colors.red, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Plan Expired",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 15, height: 1.5),
                      children: [
                        const TextSpan(text: "Your "),
                        TextSpan(
                          text: planName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const TextSpan(
                          text:
                              " subscription has expired. Access to dashboards and management is currently restricted.",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Renew Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF206C5E), // Sambalam Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onRenew,
                      icon: const Icon(Icons.credit_card),
                      label: const Text("Renew Plan Now",
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Kindly renew to continue managing your workspace.",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

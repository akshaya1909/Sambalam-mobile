import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart'; // Adjust path if needed
import '../../services/storage_service.dart'; // Adjust path if needed
import '../auth/login/login_screen.dart'; // Adjust path if needed

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Your Primary Color Palette
  static const Color _primary = Color(0xFF206C5E);
  static const Color _primaryGradientEnd =
      Color(0xFF2BA98A); // Gradient end color

  final List<OnboardingPageModel> _pages = [
    const OnboardingPageModel(
      title: 'Effortless Attendance',
      description:
          'Mark your attendance with ease using location and face verification. No more manual registers or buddy punching.',
      icon: Icons.location_on_outlined,
    ),
    const OnboardingPageModel(
      title: 'Salary Management',
      description:
          'View your salary details, PF, ESI, and tax deductions in one place. Get complete transparency on your earnings.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    const OnboardingPageModel(
      title: 'Leave Management',
      description:
          'Apply for leaves, check your balance, and get approvals - all from your mobile. Stay updated on your team\'s availability.',
      icon: Icons.event_note_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // 1. Get the StorageService instance
    final storageService = Provider.of<StorageService>(context, listen: false);

    // 2. Mark as completed in SharedPreferences
    await storageService.setOnboardingComplete(true);

    // 3. Optional: If you have specific logic in AuthService, keep it
    // final authService = Provider.of<AuthService>(context, listen: false);
    // await authService.completeOnboarding();

    if (!mounted) return;

    // 4. Navigate to login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page View Area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => _OnboardingPageItem(
                  model: _pages[index],
                  primaryColor: _primary,
                ),
              ),
            ),

            // Bottom Control Area (Indicators + Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: index == _currentPage
                            ? 24
                            : 8, // Elongate active dot
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: index == _currentPage
                              ? _primary
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),

                  // Gradient Button
                  InkWell(
                    onTap: _nextPage,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 14.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primary, _primaryGradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage < _pages.length - 1
                                ? 'Next'
                                : 'Get Started',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Model Class for Page Data
class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
  });
}

// Widget for individual pages content
class _OnboardingPageItem extends StatelessWidget {
  final OnboardingPageModel model;
  final Color primaryColor;

  const _OnboardingPageItem({
    Key? key,
    required this.model,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08), // Light tint background
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  model.icon,
                  size: 80,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            model.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            model.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

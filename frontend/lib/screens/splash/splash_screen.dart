import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/utils.dart'; // Ensure AppConstants is here
import '../../utils/routes.dart';
import '../../screens/home/branch_admin_home_screen.dart';
import '../home/attendance_manager_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Primary Gradient Colors
  final Color _primaryStart = const Color(0xFF206C5E);
  final Color _primaryEnd = const Color(0xFF2BA98A);

  @override
  void initState() {
    super.initState();

    // Setup refined animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut, // Smooth bouncy entry
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    _checkAuthStatusAndNavigate();
  }

  Future<void> _checkAuthStatusAndNavigate() async {
    // Branding time
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final storageService = Provider.of<StorageService>(context, listen: false);

    // Check onboarding
    final bool onboardingComplete = storageService.getOnboardingComplete();
    if (!onboardingComplete) {
      Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      return;
    }

    // Check Login persistence
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    final bool isAdmin = prefs.getBool('isAdmin') ?? false;
    final String? role = prefs.getString('userRole'); // Retrieve stored role
    final String? phone = prefs.getString('userPhone');
    final String? companyId = prefs.getString('companyId');
    final String? employeeId = prefs.getString('employeeId');

    if (userId != null && userId.isNotEmpty) {
      final String roleLower = role?.toLowerCase() ?? '';
      if (roleLower == 'admin') {
        Navigator.of(context)
            .pushReplacementNamed(Routes.adminHome, arguments: {
          'role': 'admin',
          'phoneNumber': phone,
        });
      } else if (roleLower == 'branch admin') {
        // 3. RETRIEVE THE BRANCHES STORED DURING LOGIN
        final List<String> branches =
            prefs.getStringList('assignedBranches') ?? [];

        // Navigate to the wrapper screen specifically designed for Branch Admins
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => BranchAdminHomeScreen(
              phoneNumber: phone ?? '',
              companyId: companyId ?? '',
              allowedBranchIds: branches,
            ),
          ),
          (route) => false,
        );
      } else if (roleLower == 'attendance manager') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AttendanceManagerHomeScreen(
              phoneNumber: phone ?? '',
              companyId: companyId ?? '',
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context)
            .pushReplacementNamed(Routes.employeeHome, arguments: {
          'phoneNumber': phone,
          'companyId': companyId,
        });
      }
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: Stack(
        children: [
          // Background Design (Subtle circles for professional touch)
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: _primaryStart.withOpacity(0.03),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Animated Logo
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: SizedBox(
                    width: size.width * 0.5, // Slightly smaller width
                    height: size.width * 0.35,
                    child: Image.asset(
                      'assets/images/logo2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 2. Gradient App Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [_primaryStart, _primaryEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        child: const Text(
                          'Sambalam',
                          style: TextStyle(
                            fontFamily: 'Sambalam', // Custom font
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Updated Tagline
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Simplified Attendance, Payroll & HR Management',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B), // Slate grey for clarity
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Initializing State
          Positioned(
            bottom: size.height * 0.06,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryStart),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing System...',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

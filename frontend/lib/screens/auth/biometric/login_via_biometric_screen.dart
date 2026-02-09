import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../home/home_screen.dart';
import '../company/choose_company_option_screen.dart';
import '../login/login_screen.dart';

class LoginViaBiometricScreen extends StatefulWidget {
  final String phoneNumber;
  const LoginViaBiometricScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<LoginViaBiometricScreen> createState() =>
      _LoginViaBiometricScreenState();
}

class _LoginViaBiometricScreenState extends State<LoginViaBiometricScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  bool _isLoading = false;
  bool _biometricEnabled = false;

  // Primary Color Palette
  static const Color _primary = Color(0xFF206C5E);
  static const Color _primaryGradientEnd = Color(0xFF2BA98A);

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadBiometricPreference();
  }

  Future<void> _checkBiometricAvailability() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }

    if (!mounted) return;
    setState(() {
      _isBiometricAvailable = canCheckBiometrics;
    });
  }

  Future<void> _loadBiometricPreference() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final enabled = await storageService.getBiometricEnabled();

    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      if (value && !_biometricEnabled) {
        bool authenticated = await _authenticateWithBiometrics();
        if (!authenticated) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await storageService.setBiometricEnabled(value);

      if (!mounted) return;
      setState(() {
        _biometricEnabled = value;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Biometric login ${value ? 'enabled' : 'disabled'}'),
          backgroundColor: _primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Error authenticating: $e');
      return false;
    }
  }

  Future<void> _continueToNextScreen() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.companyId != null) {
      // Navigate to LoginScreen to finalize the session
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Clears the navigation stack
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChooseCompanyOptionScreen(
            phoneNumber: widget.phoneNumber,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.02),

              // Animated Illustration Area
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 80,
                    color: _primary,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Biometric Login',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Use your fingerprint or face ID for a faster\nand more secure login experience.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Status / Toggle Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _biometricEnabled
                        ? _primary.withOpacity(0.5)
                        : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    if (_isBiometricAvailable)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _biometricEnabled
                                  ? _primary
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.security,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Biometrics',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Fingerprint or Face ID',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _biometricEnabled,
                            activeColor: _primary,
                            onChanged: _isLoading ? null : _toggleBiometric,
                          ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.redAccent),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Biometric authentication is not supported on this device.',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // Gradient Continue Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryGradientEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continueToNextScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Continue to Dashboard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Skip option
              Center(
                child: TextButton(
                  onPressed: _continueToNextScreen,
                  child: Text(
                    'Set up later',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
}

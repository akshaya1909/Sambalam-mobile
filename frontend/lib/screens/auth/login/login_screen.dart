import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../otp/otp_screen.dart';
import '../secure_pin/secure_pin_screen.dart';
import '../company/select_company_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _companyId = '';
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Primary Color Palette
  static const Color _primary = Color(0xFF206C5E);
  static const Color _primaryGradientEnd = Color(0xFF2BA98A);

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['message'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(args['message']),
            backgroundColor: _primary,
          ),
        );
      });
    }
  }

  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getString('companyId') ?? '';
    });
  }

  Future<void> _checkBiometrics() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Only show biometrics if user has enabled it and is already registered
    if (authService.biometricEnabled) {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        _showBiometricPrompt();
      }
    }
  }

  Future<void> _showBiometricPrompt() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        // Navigate to secure pin screen if biometric authentication succeeds
        final prefs = await SharedPreferences.getInstance();
        final lastRole = prefs.getString('userRole') ?? 'employee';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SecurePinScreen(
              phoneNumber:
                  _phoneController.text, // Note: Might be empty if fresh launch
              companyId: _companyId,
              role: lastRole,
            ),
          ),
        );
      }
    } catch (e) {
      // Biometric authentication failed or was canceled
      debugPrint("Biometric error: $e");
    }
  }

  Future<void> _login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userData =
            await authService.checkPhoneExists(_phoneController.text);

        if (!mounted) return;

        if (userData['exists'] == true) {
          if (userData['isVerified'] == true) {
            // User already registered and has PIN -> Select Company Flow
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SelectCompanyScreen(
                  phoneNumber: _phoneController.text,
                ),
              ),
            );
          } else {
            // User exists but no PIN -> go to OTP for setup
            await authService.sendOtp(_phoneController.text);
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OtpScreen(phoneNumber: _phoneController.text),
              ),
            );
          }
        } else {
          // New user -> go to OTP screen
          await authService.sendOtp(_phoneController.text);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpScreen(phoneNumber: _phoneController.text),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Managed manually via Padding
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            // Ensures content pushes up when keyboard opens
            padding: EdgeInsets.only(
              bottom: bottomInset > 0 ? bottomInset + 20 : 20,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.02),

                  // --- Logo Section ---
                  Container(
                    width: 220,
                    height: 220,
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Image.asset(
                        'assets/images/logo2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // --- Headings ---
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered phone number\nto continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- Form Section ---
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            hintText: '9876543210',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                '+91',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 0, minHeight: 0),
                            counterText: "", // Hides the character counter
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: _primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: Colors.redAccent),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length != 10) {
                              return 'Phone number must be 10 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // --- Gradient Login Button ---
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
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
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward,
                                          color: Colors.white),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- Biometric Login Button (if enabled) ---
                        if (authService.biometricEnabled)
                          TextButton.icon(
                            onPressed: _showBiometricPrompt,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: _primary,
                            ),
                            icon: const Icon(Icons.fingerprint, size: 28),
                            label: const Text(
                              'Login with Biometrics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // Extra spacing for small screens
                        SizedBox(height: size.height * 0.05),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

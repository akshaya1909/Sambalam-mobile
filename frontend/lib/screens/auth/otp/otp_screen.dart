import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../secure_pin/create_secure_pin_screen.dart';
import '../company/choose_company_option_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isResettingPin; // Add this
  final String? companyId;

  const OtpScreen({
    Key? key,
    required this.phoneNumber,
    this.isResettingPin = false, // Default to false
    this.companyId,
  }) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 30;
  Timer? _timer;

  // Primary Color Palette
  static const Color _primary = Color(0xFF206C5E);
  static const Color _primaryGradientEnd = Color(0xFF2BA98A);

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // 1. Call the service to trigger Firebase to send a new code
      await authService.sendOtp(widget.phoneNumber);

      // 2. Reset the timer and UI state
      _startResendTimer();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new code has been sent to your phone'),
          backgroundColor: _primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to resend OTP: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dynamic result =
          await authService.verifyOtp(widget.phoneNumber, otp);
      if (!mounted) return;

      if (result is bool) {
        bool hasCompanies = result;

        if (widget.isResettingPin) {
          // BRANCH 1: RESETTING PIN
          // Navigate to CreateSecurePinScreen in Reset Mode
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CreateSecurePinScreen(
                phoneNumber: widget.phoneNumber,
                isResetMode: true,
                // Pass the companyId if you have it, so the PIN updates the correct membership
                companyId: widget.companyId ?? "",
              ),
            ),
          );
        } else if (hasCompanies) {
          // BRANCH 2: EXISTING USER LOGIN
          // User exists in DB and belongs to a company but needs to set/re-verify PIN
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CreateSecurePinScreen(
                phoneNumber: widget.phoneNumber,
                companyId: widget.companyId ?? "",
                isResetMode: false,
              ),
            ),
          );
        } else {
          // BRANCH 3: BRAND NEW USER
          // User is verified but has no company associations yet
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ChooseCompanyOptionScreen(
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      } else {
        // Verification failed at the backend level
        _showError('Invalid OTP. Please try again.');
      }
    } catch (e) {
      _showError('Verification failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header Icon
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.mark_email_read_outlined,
                      size: 40, color: _primary),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verification Code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 15, color: Colors.grey, height: 1.5),
                  children: [
                    const TextSpan(
                        text: 'We have sent the verification code to\n'),
                    TextSpan(
                      text: '+91 ${widget.phoneNumber}',
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // OTP Fields Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: (size.width - 80) / 6,
                    child: RawKeyboardListener(
                      focusNode:
                          FocusNode(), // Dummy node for backspace detection
                      onKey: (event) {
                        if (event is RawKeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.backspace &&
                            _controllers[index].text.isEmpty &&
                            index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        autofocus: index == 0,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _primary, width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (index == 5 && value.isNotEmpty) {
                            _verifyOtp();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Gradient Verify Button
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
                  onPressed: _isLoading ? null : _verifyOtp,
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
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Resend Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  _resendSeconds > 0
                      ? Text(
                          'Resend in $_resendSeconds s',
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : TextButton(
                          onPressed: _resendOtp,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Resend Now',
                            style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

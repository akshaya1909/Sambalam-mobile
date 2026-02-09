import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../biometric/login_via_biometric_screen.dart';
import '../company/choose_company_option_screen.dart';

class CreateSecurePinScreen extends StatefulWidget {
  final String phoneNumber;
  final String companyId;
  final bool isResetMode;

  const CreateSecurePinScreen({
    Key? key,
    required this.phoneNumber,
    required this.companyId,
    this.isResetMode = false,
  }) : super(key: key);

  @override
  State<CreateSecurePinScreen> createState() => _CreateSecurePinScreenState();
}

class _CreateSecurePinScreenState extends State<CreateSecurePinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePin = true;

  // Primary Color Palette
  static const Color _primary = Color(0xFF206C5E);
  static const Color _primaryGradientEnd = Color(0xFF2BA98A);

  bool _isMobileDevice() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _createPin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.length != 4 || confirmPin.length != 4) {
      _showSnackBar('Please enter both 4-digit PINs');
      return;
    }

    if (pin != confirmPin) {
      _showSnackBar('PINs do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      bool success;
      if (widget.isResetMode) {
        // Use the new resetPin service
        success = await authService.resetPin(
            widget.phoneNumber, pin, widget.companyId);
      } else {
        // Use existing create service
        success = await authService.createUserWithPin(
            widget.phoneNumber, pin, widget.companyId);
      }

      if (!mounted) return;

      if (success) {
        _showSnackBar(widget.isResetMode
            ? 'PIN reset successfully!'
            : 'User created successfully!');
        if (widget.isResetMode) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Standard flow for new user creation
          if (_isMobileDevice()) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    LoginViaBiometricScreen(phoneNumber: widget.phoneNumber),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    ChooseCompanyOptionScreen(phoneNumber: widget.phoneNumber),
              ),
            );
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
              const Center(
                child: Icon(Icons.security_rounded, size: 70, color: _primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Set Secure PIN',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a 4-digit PIN to secure your account',
                style: TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- New PIN Section ---
              _buildPinSection(
                label: "ENTER NEW PIN",
                controller: _pinController,
                autoFocus: true,
              ),

              const SizedBox(height: 32),

              // --- Confirm PIN Section ---
              _buildPinSection(
                label: "CONFIRM PIN",
                controller: _confirmPinController,
                autoFocus: false,
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  icon: Icon(
                      _obscurePin ? Icons.visibility : Icons.visibility_off,
                      size: 18),
                  label: Text(_obscurePin ? 'Show PINs' : 'Hide PINs'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                ),
              ),

              const SizedBox(height: 40),

              // Gradient Create Button
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
                  onPressed: _isLoading ? null : _createPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Create PIN',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinSection({
    required String label,
    required TextEditingController controller,
    required bool autoFocus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Stack(
          children: [
            // 1. HIDDEN LAYER: Sized to match the new larger boxes
            SizedBox(
              height: 80, // Matches visual box height
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: autoFocus,
                maxLength: 4,
                // Make text invisible and large enough to be "hittable"
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 24,
                  letterSpacing: 45,
                ),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: "",
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  setState(() {});
                  // Auto-focus move to next field (Confirm PIN)
                  if (val.length == 4 && autoFocus) {
                    FocusScope.of(context).nextFocus();
                  }
                },
              ),
            ),

            // 2. VISIBLE LAYER: Increased size boxes
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  String char = "";
                  if (controller.text.length > index) {
                    char = _obscurePin ? "●" : controller.text[index];
                  }

                  bool isFocused = controller.text.length == index;

                  return Container(
                    width: 65, // Increased width
                    height: 70, // Increased height
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius:
                          BorderRadius.circular(16), // Rounded corners
                      border: Border.all(
                        color: isFocused ? _primary : Colors.grey[300]!,
                        width: 2.5, // Slightly thicker border for larger boxes
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: _primary.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      char,
                      style: TextStyle(
                        fontSize: char == "●" ? 20 : 26, // Larger text
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../api/api_service.dart';
import '../../home/employee_home_screen.dart';
import '../../home/admin_home_screen.dart';
import '../../home/attendance_manager_home_screen.dart';
import '../../home/branch_admin_home_screen.dart';
import '../otp/otp_screen.dart';
import '../../../services/notification_service.dart';
import '../device_verification/device_pending_screen.dart';

class SecurePinScreen extends StatefulWidget {
  final String phoneNumber;
  final String companyId;
  final String role;

  const SecurePinScreen({
    Key? key,
    required this.phoneNumber,
    required this.companyId,
    required this.role,
  }) : super(key: key);

  @override
  State<SecurePinScreen> createState() => _SecurePinScreenState();
}

class _SecurePinScreenState extends State<SecurePinScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;

  // Colors based on your theme
  static const Color _primary = Color(0xFF206C5E);
  static const Color _primaryGradientEnd = Color(0xFF2BA98A);

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _savePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit PIN')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await authService.verifyPin(
        widget.phoneNumber,
        pin,
        widget.companyId,
        widget.role,
      );

      if (!mounted) return;
      debugPrint('DEBUG: verifyPin success = $result');
      if (result == 'success') {
        debugPrint('DEBUG: userRole = ${authService.userRole}');
        debugPrint('DEBUG: userId = ${authService.userId}');
        debugPrint('DEBUG: employeeId = ${authService.employeeId}');
        debugPrint('DEBUG: adminId = ${authService.adminId}');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('companyId', widget.companyId);
        await prefs.setString('userRole', widget.role);

        final userId = authService.userId ?? '';
        final roleStr = widget.role.toLowerCase();

        if (authService.employeeId != null) {
          await prefs.setString('employeeId', authService.employeeId!);
        }
        if (authService.adminId != null) {
          await prefs.setString('adminId', authService.adminId!);
        }

        await prefs.setBool('isAdmin', widget.role == 'admin');
        await prefs.setString('userId', userId);
        await prefs.setString('userPhone', widget.phoneNumber);

        // Register FCM token
        await NotificationService.registerFcmToken();

        Widget homeWidget;
        if (roleStr == 'admin') {
          homeWidget = AdminHomeScreen(
            role: 'admin',
            onAddStaff: () {},
            onInviteStaff: () {},
            onReports: () {},
            onEditAttendance: () {},
            onHelp: () {},
            planExpiryBanner: "Welcome Admin",
            phoneNumber: widget.phoneNumber,
          );
        } else if (roleStr == 'branch admin') {
          // Add 'await' here to resolve the Future into an actual List<String>
          final List<String> assignedBranches =
              await apiService.getAssignedBranches(widget.companyId);

          if (widget.role.toLowerCase() == 'branch admin') {
            // assignedBranches is the List<String> from your API
            await prefs.setStringList('assignedBranches', assignedBranches);
          }

          homeWidget = BranchAdminHomeScreen(
            phoneNumber: widget.phoneNumber,
            companyId: widget.companyId,
            allowedBranchIds: assignedBranches,
          );
        } else if (roleStr == 'attendance manager') {
          // ADD THIS BLOCK
          homeWidget = AttendanceManagerHomeScreen(
            phoneNumber: widget.phoneNumber,
            companyId: widget.companyId,
          );
        } else {
          homeWidget = EmployeeHomeScreen(
            phoneNumber: widget.phoneNumber,
            companyId: widget.companyId,
            hideInternalNav: false,
          );
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => homeWidget),
          (route) => false,
        );
      } else if (result == 'pending') {
        // --- NEW FLOW: DEVICE CHANGE DETECTED ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'New device detected! Request submitted for Admin approval.'),
            backgroundColor: Color(0xFF206C5E),
          ),
        );

        // Move to the blocked screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DevicePendingScreen()),
        );
      } else {
        _pinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid PIN. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: size.height * 0.02),

                // Security Icon
                const Center(
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: _primary,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Verify Your Identity',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the 4-digit secure PIN for\n${widget.phoneNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Stylized PIN Input
                Stack(
                  children: [
                    // 1. HIDDEN TEXT FIELD (Sized to match the boxes)
                    SizedBox(
                      height: 65, // Matches the height of your visible boxes
                      child: TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        maxLength: 4,
                        // Make text transparent so it doesn't show behind the boxes
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize:
                              24, // Give it a real size so it's "hittable"
                          letterSpacing:
                              40, // Spreads characters across the width
                        ),
                        cursorColor: Colors.transparent,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: "",
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) {
                          if (val.length == 4) _verifyPin();
                          setState(() {});
                        },
                      ),
                    ),

                    // 2. VISIBLE PIN BOXES ON TOP
                    IgnorePointer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          String char = "";
                          if (_pinController.text.length > index) {
                            char =
                                _obscurePin ? "●" : _pinController.text[index];
                          }

                          bool isFocused = _pinController.text.length == index;

                          return Container(
                            width: 60,
                            height: 65,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isFocused ? _primary : Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: isFocused
                                  ? [
                                      BoxShadow(
                                        color: _primary.withOpacity(0.1),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              char,
                              style: TextStyle(
                                fontSize: char == "●" ? 18 : 24,
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

                const SizedBox(height: 16),

                // Toggle Visibility
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    icon: Icon(
                        _obscurePin ? Icons.visibility : Icons.visibility_off,
                        size: 18),
                    label: Text(_obscurePin ? 'Show PIN' : 'Hide PIN'),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.grey[600]),
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
                    onPressed: _isLoading ? null : _verifyPin,
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
                            'Verify & Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () async {
                    // 1. Show loading indicator if desired, or disable button
                    setState(() => _isLoading = true);

                    try {
                      final authService =
                          Provider.of<AuthService>(context, listen: false);

                      // 2. Trigger OTP and wait for 'codeSent' callback
                      await authService.sendOtp(widget.phoneNumber);

                      if (!mounted) return;

                      // 3. Navigate only AFTER the code is sent to the emulator console
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OtpScreen(
                            phoneNumber: widget.phoneNumber,
                            isResettingPin: true, // Flag to identify reset flow
                            companyId: widget.companyId,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Failed to send OTP: ${e.toString()}')),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  child: const Text(
                    'Forgot PIN?',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
}

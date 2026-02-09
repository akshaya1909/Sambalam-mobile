import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../company/join_company_user_details_screen.dart';

class EnterCompanyScreen extends StatefulWidget {
  final String phoneNumber;
  const EnterCompanyScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<EnterCompanyScreen> createState() => _EnterCompanyScreenState();
}

class _EnterCompanyScreenState extends State<EnterCompanyScreen> {
  final _companyIdController = TextEditingController();
  bool _isLoading = false;

  // Primary Gradient Colors
  final Color _primaryStart = const Color(0xFF206C5E);
  final Color _primaryEnd = const Color(0xFF2BA98A);

  @override
  void dispose() {
    _companyIdController.dispose();
    super.dispose();
  }

  Future<void> _submitCompanyId() async {
    if (_companyIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter company ID')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final companyId = await authService.setCompanyId(
        _companyIdController.text.trim(),
        widget.phoneNumber,
      );

      if (!mounted) return;

      if (companyId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => JoinCompanyUserDetailsScreen(
              companyId: companyId,
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid company ID. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          // Prevents pixel breakage when keyboard opens
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Enter Company Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enter your company code to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Company ID field with themed border
                TextFormField(
                  controller: _companyIdController,
                  decoration: InputDecoration(
                    labelText: 'Company Code',
                    labelStyle: TextStyle(color: _primaryStart),
                    prefixIcon: Icon(Icons.business, color: _primaryStart),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryStart, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onFieldSubmitted: (_) => _submitCompanyId(),
                ),
                const SizedBox(height: 24),

                // Gradient Submit Button
                _buildGradientButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? null
            : LinearGradient(
                colors: [_primaryStart, _primaryEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _isLoading ? Colors.grey : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: _primaryStart.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitCompanyId,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

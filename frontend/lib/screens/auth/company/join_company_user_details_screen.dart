import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../api/api.dart'; // ApiService
import '../../../widgets/widgets.dart'; // CustomAppBar, LoadingWidget

class JoinCompanyUserDetailsScreen extends StatefulWidget {
  final String companyId;
  final String phoneNumber;

  const JoinCompanyUserDetailsScreen({
    Key? key,
    required this.companyId,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<JoinCompanyUserDetailsScreen> createState() =>
      _JoinCompanyUserDetailsScreenState();
}

class _JoinCompanyUserDetailsScreenState
    extends State<JoinCompanyUserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  File? _profileImage;
  Uint8List? _webImage;
  String? _imageName;
  bool _isLoading = false;

  // Primary Gradient Colors
  final Color _primaryStart = const Color(0xFF206C5E);
  final Color _primaryEnd = const Color(0xFF2BA98A);

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _webImage = bytes;
        _imageName = pickedFile.name; // Get filename
        if (!kIsWeb) {
          _profileImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      await apiService.createJoinRequest(
        companyId: widget.companyId,
        phoneNumber: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        imageBytes: _webImage,
        imageName: _imageName,
        imagePath: kIsWeb ? null : _profileImage?.path,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request submitted! Waiting for admin approval.'),
          backgroundColor: Color(0xFF206C5E),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Join Request',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: _primaryStart,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryStart))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Image Picker
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: _primaryStart.withOpacity(0.1),
                                backgroundImage: kIsWeb
                                    ? (_webImage != null
                                        ? MemoryImage(_webImage!)
                                        : null) as ImageProvider?
                                    : (_profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null) as ImageProvider?,
                                child:
                                    (_profileImage == null && _webImage == null)
                                        ? Icon(Icons.person,
                                            size: 60, color: _primaryStart)
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [_primaryStart, _primaryEnd]),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Input Fields
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_android_outlined,
                        readOnly: true, // Phone usually fixed from OTP
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email (Optional)',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 40),

                      // Themed Gradient Button
                      _buildGradientButton(),

                      const SizedBox(height: 20),
                      const Text(
                        'Your request will be sent to the company admin for approval.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Common UI helper for Text Fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: readOnly ? Colors.grey : _primaryStart),
        prefixIcon: Icon(icon, color: _primaryStart),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryStart, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Common UI helper for Gradient Button
  Widget _buildGradientButton() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryStart, _primaryEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryStart.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'SUBMIT JOIN REQUEST',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

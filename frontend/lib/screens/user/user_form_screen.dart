import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../api/api.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({Key? key, this.user}) : super(key: key);

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'employee';
  File? _profileImage;
  bool _isLoading = false;
  String? _companyId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    if (widget.user != null) {
      _nameController.text = widget.user?.name ?? '';
      _phoneController.text = widget.user?.phoneNumber ?? '';
      _emailController.text = widget.user?.email ?? '';
      _selectedRole = widget.user?.role ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    setState(() {
      _userId = user?['id'];
      _companyId = user?['companyId'];
    });

    if (_companyId == null || user?['role'] != 'admin') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You do not have permission to access this page')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      if (widget.user == null) {
        // Create new user
        await apiService.createUser(
  companyId: _companyId!,
  name: _nameController.text,
  phoneNumber: _phoneController.text,
  email: _emailController.text.isNotEmpty ? _emailController.text : null,
  role: _selectedRole,
  profileImage: _profileImage,
);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
      } else {
        // Update existing user
      
await apiService.updateUser(
  id: widget.user!.id,
  name: _nameController.text,
  phoneNumber: _phoneController.text,
  email: _emailController.text.isNotEmpty ? _emailController.text : null,
  role: _selectedRole,
  profileImage: _profileImage,
);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving user: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.user == null ? 'Add User' : 'Edit User',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Saving user...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : widget.user?.profileImage != null
                                      ? NetworkImage(widget.user!.profileImage!)
                                          as ImageProvider
                                      : null,
                              child: (_profileImage == null &&
                                      widget.user?.profileImage == null)
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.primaryColor,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        // Add phone number validation if needed
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // Simple email validation
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'User Role',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'employee', child: Text('Employee')),
                        DropdownMenuItem(
                            value: 'hr', child: Text('HR Manager')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          widget.user == null ? 'ADD USER' : 'UPDATE USER',
                          style: const TextStyle(fontSize: 16),
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

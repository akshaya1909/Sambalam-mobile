import 'package:flutter/material.dart';

import '../../../api/api_service.dart';
import 'create_company_screen.dart';

class CreateCompanyDialog extends StatefulWidget {
  final String phoneNumber;

  const CreateCompanyDialog({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<CreateCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _createCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.createCompany(
        name: _companyNameController.text,
        phoneNumber: widget.phoneNumber,
        staffCount: 1, // default value
        category: null, // optional
        sendWhatsappAlerts: true,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Company created! Code: ${result['company_code']}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Return true to indicate success
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Company'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: 'Company Name',
                hintText: 'Enter company name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a company name';
                }
                if (value.trim().length < 3) {
                  return 'Company name must be at least 3 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCompany,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

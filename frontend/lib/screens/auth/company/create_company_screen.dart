import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../utils/company_categories.dart';
import '../../../utils/input_formatters.dart';
import '../company/add_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateCompanyScreen extends StatefulWidget {
  final String phoneNumber;
  const CreateCompanyScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _companyNameController = TextEditingController();
  final _staffCountController = TextEditingController();
  bool _isLoading = false;
  String? _selectedCategory;
  bool _sendWhatsappAlerts = true;

  // Primary Gradient Colors
  static const Color _primaryStart = Color(0xFF206C5E);
  static const Color _primaryEnd = Color(0xFF2BA98A);

  @override
  void dispose() {
    _companyNameController.dispose();
    _staffCountController.dispose();
    super.dispose();
  }

  Future<void> _selectCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Select Company Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: companyCategories.length,
                    itemBuilder: (context, index) {
                      final cat = companyCategories[index];
                      return ListTile(
                        title: Text(cat),
                        onTap: () => Navigator.of(context).pop(cat),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedCategory = selected);
    }
  }

  Future<void> _submitCompany() async {
    // 1. Validation
    if (_companyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter company name')),
      );
      return;
    }
    final String rawValue = _staffCountController.text.replaceAll(',', '');
    final staffCount = int.tryParse(rawValue);

    // final staffCount = int.tryParse(_staffCountController.text.trim());
    if (staffCount == null || staffCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid staff count')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final companyId = await authService.createCompany(
        _companyNameController.text.trim(),
        widget.phoneNumber,
        staffCount,
        _selectedCategory,
        _sendWhatsappAlerts,
      );

      if (companyId != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('companyId', companyId);

        final authService = Provider.of<AuthService>(context, listen: false);

        // NEW: Check if we need to ask for details
        bool detailsExist =
            await authService.hasAdminDetails(widget.phoneNumber);

        if (detailsExist) {
          // Link the new company silently and skip the screen
          await authService.saveAdminAndAdvertiseDetails(
            name:
                "Existing", // Backend will ignore name/email if profile exists
            email: "",
            phoneNumber: widget.phoneNumber,
            companyId: companyId,
            features: [],
          );
          Navigator.of(context).pop(true);
          Navigator.of(context).pushReplacementNamed('/login'); // Or Dashboard
        } else {
          // First time user, show the details screen
          Navigator.of(context).pop(true);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddDetailsScreen(phoneNumber: widget.phoneNumber),
            ),
          );
        }
      }
    } catch (e) {
      print("Error creating company: $e"); // Check your console!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        // Prevents pixel breakage on small screens
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  // Using _primaryStart to match the dark part of your button gradient
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: _primaryStart),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 24, // Optional: makes the ripple effect smaller
                ),
              ),
              const Text(
                'Create Company',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter your company details to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _companyNameController,
                decoration: InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'XYZ Pvt Ltd',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
                onFieldSubmitted: (_) => _submitCompany(),
              ),
              const SizedBox(height: 34),
              TextFormField(
                controller: _staffCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly, // Allow only digits initially
                  CommaTextInputFormatter(), // Apply comma formatting
                ],
                decoration: InputDecoration(
                  labelText: 'Staff Count',
                  hintText: 'eg. 1,500',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.groups),
                ),
              ),
              const SizedBox(height: 34),
              GestureDetector(
                onTap: _selectCategory,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Category (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedCategory ?? 'Select'),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Send free Whatsapp alerts'),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _sendWhatsappAlerts,
                      activeColor: _primaryStart, // Match primary color
                      onChanged: (v) => setState(() => _sendWhatsappAlerts = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gradient Button Implementation
              Container(
                height: 50, // Standard button height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [_primaryStart, _primaryEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryStart.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCompany,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Company',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../secure_pin/create_secure_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddDetailsScreen extends StatefulWidget {
  final String phoneNumber;

  const AddDetailsScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<AddDetailsScreen> createState() => _AddDetailsScreenState();
}

class _AddDetailsScreenState extends State<AddDetailsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedRole;
  List<String> _selectedFeatures = [];
  String? _selectedHeardFrom;
  String? _selectedSalaryRange;

  bool _isSubmitting = false;

  // Primary Gradient Colors
  static const Color _primaryStart = Color(0xFF206C5E);
  static const Color _primaryEnd = Color(0xFF2BA98A);

  final List<String> _roles = [
    'Owner',
    'HR',
    'Manager',
    'Admin',
    'Other',
  ];

  final List<String> _features = [
    'Attendance Tracking',
    'Biometric Device',
    'Payroll',
    'Location Tracking',
    'Salary Payouts',
    'Document Storage',
    'Team Communication',
    'Roster',
  ];

  final List<String> _heardFrom = [
    'Play Store Search',
    'From Friend or Family',
    'Social Media like Facebook or Instagram',
    'Google Search',
    'Youtube',
  ];

  final List<String> _salaryRanges = [
    '<1 Lakh',
    '1 Lakh to 3 Lakh',
    '3 Lakh+',
    "I don't know",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectFromList({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.42,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final item = options[index];
                      return ListTile(
                        title: Text(item),
                        onTap: () => Navigator.of(context).pop(item),
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
      onSelected(selected);
    }
  }

  Future<void> _selectFeature() async {
    List<String> tempSelected = List<String>.from(_selectedFeatures);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.7,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Select features you are interested in',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: _features.length,
                        itemBuilder: (context, index) {
                          final feature = _features[index];
                          final isChecked = tempSelected.contains(feature);
                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  tempSelected.add(feature);
                                } else {
                                  tempSelected.remove(feature);
                                }
                              });
                            },
                            title: Text(feature),
                            activeColor: _primaryStart,
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [_primaryStart, _primaryEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedFeatures = tempSelected;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitDetails() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId == null) {
        throw Exception('Company ID not found in local storage');
      }

      await authService.saveAdminAndAdvertiseDetails(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: widget.phoneNumber,
        companyId: companyId,
        features: _selectedFeatures,
        heardFrom: _selectedHeardFrom,
        salaryRange: _selectedSalaryRange,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => CreateSecurePinScreen(
      phoneNumber: widget.phoneNumber,
      companyId: companyId, // Ensure you have access to the companyId from local storage or previous screen
      isResetMode: false,
    ),
  ),
);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _fieldDecoration({
    String? label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryStart, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> safeFeatures =
        (_selectedFeatures is List<String>) ? _selectedFeatures : <String>[];

    final String featuresText =
        safeFeatures.isNotEmpty ? safeFeatures.join(', ') : 'Select';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add your details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tell us more about you to personalise your experience',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: _fieldDecoration(
                  label: 'Your Name',
                  hint: 'Enter Name',
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration(
                  label: 'Email',
                  hint: 'eg. example@mail.com',
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _selectFeature,
                child: InputDecorator(
                  decoration: _fieldDecoration(
                    label: 'Features you are interested in (Optional)',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          featuresText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => _selectFromList(
                  title: 'Select how did you hear about us',
                  options: _heardFrom,
                  onSelected: (v) => setState(() => _selectedHeardFrom = v),
                ),
                child: InputDecorator(
                  decoration: _fieldDecoration(
                    label: 'How did you hear about us (Optional)',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _selectedHeardFrom ?? 'Select',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => _selectFromList(
                  title: 'Select how much salary do you pay monthly',
                  options: _salaryRanges,
                  onSelected: (v) => setState(() => _selectedSalaryRange = v),
                ),
                child: InputDecorator(
                  decoration: _fieldDecoration(
                    label: 'How much salary do you pay monthly (Optional)',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedSalaryRange ?? 'Select'),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 50,
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
                  onPressed: _isSubmitting ? null : _submitDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
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
                          'Continue',
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

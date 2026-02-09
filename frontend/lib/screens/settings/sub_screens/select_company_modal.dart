import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/company_settings_api_service.dart';
import '../../../../models/company_model.dart';
import '../../auth/secure_pin/secure_pin_screen.dart';

class SelectCompanyModal extends StatefulWidget {
  const SelectCompanyModal({Key? key}) : super(key: key);

  @override
  State<SelectCompanyModal> createState() => _SelectCompanyModalState();
}

class _SelectCompanyModalState extends State<SelectCompanyModal> {
  final CompanySettingsApiService _api = CompanySettingsApiService();

  List<Company> _companies = [];
  bool _isLoading = true;
  String? _phoneNumber;
  String? _selectedId;

  // Emerald Theme Colors
  static const Color primaryGreen = Color(0xFF064E3B); // Deep Emerald
  static const Color accentGreen = Color(0xFF10B981); // Bright Emerald
  static const Color lightGreenBg =
      Color(0xFFECFDF5); // Very light mint for selection

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) throw Exception('User ID not found');

      final phone = await _api.getUserPhone(userId);
      _phoneNumber = phone;

      final companies = await _api.getUserCompanies(phone);

      if (mounted) {
        setState(() {
          _companies = companies;
          _selectedId = prefs.getString('companyId');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCompanySelected(String id) {
    setState(() => _selectedId = id);
  }

  void _onConfirm() {
    if (_selectedId != null && _phoneNumber != null) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SecurePinScreen(
            phoneNumber: _phoneNumber!,
            companyId: _selectedId!,
            role: _companies.firstWhere((c) => c.id == _selectedId).role,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.75, // Responsive height
      decoration: const BoxDecoration(
        color: Colors.white, // Modal background kept white
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Company',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen, // Using deep green for title
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentGreen))
                : _buildCompanyList(),
          ),

          // Bottom Fixed Button Area
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildCompanyList() {
    if (_companies.isEmpty) {
      return const Center(
        child: Text(
          'No companies found',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _companies.length,
      itemBuilder: (context, index) {
        final company = _companies[index];
        final isSelected = _selectedId == company.id;

        return GestureDetector(
          onTap: () => _onCompanySelected(company.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? lightGreenBg : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accentGreen : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.05 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Company Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryGreen, accentGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      company.name.isNotEmpty
                          ? company.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Company Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Code: ${company.companyCode ?? 'N/A'}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkbox
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? accentGreen : Colors.grey.shade300,
                  size: 28,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _selectedId == null
              ? null
              : const LinearGradient(
                  colors: [primaryGreen, accentGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _selectedId == null ? Colors.grey.shade300 : null,
        ),
        child: ElevatedButton(
          onPressed: _selectedId == null ? null : _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

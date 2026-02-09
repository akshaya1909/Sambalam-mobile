import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/api_service.dart';
import '../../../models/company_model.dart';
import '../../../widgets/company_avatar.dart';
import '../secure_pin/secure_pin_screen.dart';
import '../secure_pin/create_secure_pin_screen.dart';
import '../company/create_company_screen.dart';
import '../company/enter_company_screen.dart';

class SelectCompanyScreen extends StatefulWidget {
  final String phoneNumber;
  const SelectCompanyScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<SelectCompanyScreen> createState() => _SelectCompanyScreenState();
}

class _SelectCompanyScreenState extends State<SelectCompanyScreen> {
  final _searchController = TextEditingController();
  List<Company> _companies = [];
  List<Company> _filteredCompanies = [];
  bool _isLoading = true;
  String? _selectedCompanyId;
  int? _selectedIndex;
  String? _error;

  // Primary Color Palette
  static const Color _primary = Color(0xFF206C5E);
  static const Color _primaryGradientEnd = Color(0xFF2BA98A);

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _searchController.addListener(_filterCompanies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final companies = await apiService.getUserCompanies(widget.phoneNumber);
      print('--- DEBUG: Company Data ---');
    print('Total companies found: ${companies.length}');
    for (var company in companies) {
      print('Name: ${company.name}');
      print('Role: ${company.role}'); // Is this ['employee'] or ['admin', 'branch admin']?
      print('Branches: ${company.branchNames}');
      print('Subtitle logic result: ${company.displaySubtitle}');
      print('--------------------------');
    }

      if (mounted) {
        setState(() {
          _companies = companies;
          _filteredCompanies = companies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterCompanies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCompanies = _companies.where((company) {
        // Check if Name matches
        final matchesName = company.name.toLowerCase().contains(query);

        // FIX: Check if any role in the list matches the query
        final matchesRole = company.role.toLowerCase().contains(query);
            
        // OPTIONAL: Also search by branch name for better UX
        final matchesBranch = company.branchNames.any((branch) => 
            branch.toLowerCase().contains(query));

        return matchesName || matchesRole || matchesBranch;
      }).toList();
    });
  }

  void _selectCompany(int index) { // Change from String companyId to int index
  setState(() {
    _selectedIndex = index;
    _selectedCompanyId = _filteredCompanies[index].id;
    // We don't strictly need _selectedCompanyId anymore since we have the index
  });
}

  void _confirmSelection() {
    if (_selectedIndex == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a workspace')),
    );
    return;
  }
final selectedWorkspace = _filteredCompanies[_selectedIndex!];

    if (selectedWorkspace.hasPin) {
      // CASE A: Company has a PIN -> Go to Login/Verify PIN Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SecurePinScreen(
            phoneNumber: widget.phoneNumber,
            companyId: selectedWorkspace.id,
            role: selectedWorkspace.role,
          ),
        ),
      );
    } else {
      // CASE B: No PIN set yet -> Go to Create PIN Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CreateSecurePinScreen(
            phoneNumber: widget.phoneNumber,
            companyId: selectedWorkspace.id, // Ensure context is passed
            isResetMode: false,
          ),
        ),
      );
    }
  }

  Future<void> _showCreateCompanyDialog() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateCompanyScreen(
          phoneNumber: widget.phoneNumber,
        ),
      ),
    );

    // Refresh list if a company was created or just reload to be safe
    if (result == true || result == null) {
      _loadCompanies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: AppBar(
        title: const Text(
          'Select Company',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for your company...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                // Add shadow effect via container decoration if needed,
                // but standard filled input looks clean on grey bg.
              ),
            ),
          ),

          // --- Section Header ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              'YOUR WORKSPACES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // --- Main List Area ---
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _filteredCompanies.isEmpty
                        ? _buildEmptyState()
                        : _buildCompanyList(),
          ),

          // --- Bottom Action Area ---
          Container(
            padding: const EdgeInsets.all(16.0),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Create New Company
                    Expanded(
                      child: _buildSecondaryButton(
                        icon: Icons.add_circle_outline,
                        label: 'Create New \nCompany',
                        onTap: _showCreateCompanyDialog,
                      ),
                    ),
                    const SizedBox(width: 12), // Gap between buttons
                    // Join Existing Company
                    Expanded(
                      child: _buildSecondaryButton(
                        icon: Icons.group_add_outlined,
                        label: 'Join Existing \nCompany',
                        onTap: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => EnterCompanyScreen(
                                    phoneNumber: widget.phoneNumber,
                                  ),
                                ),
                              )
                              .then((_) => _loadCompanies()); // Refresh on back
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _selectedCompanyId == null ? null : _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _selectedCompanyId == null
                            ? const LinearGradient(
                                colors: [Colors.grey, Colors.grey])
                            : const LinearGradient(
                                colors: [_primary, _primaryGradientEnd],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Confirm Selection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: _primary.withOpacity(0.5), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: _primary.withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _primary, size: 20),
            const SizedBox(width: 8),
            Flexible(
              // Use Flexible to prevent overflow
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13, // Slightly smaller for 2-column layout
                  fontWeight: FontWeight.w600,
                  color: _primary,
                  height: 1.2,
                ),
                // maxLines: 1,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCompanies.length,
      itemBuilder: (context, index) {
        final company = _filteredCompanies[index];
        final isSelected = _selectedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () => _selectCompany(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isSelected ? _primary.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  CompanyAvatar(
                    name: company.name,
                    // If you have a logo URL in your model, pass it here:
                    // imageUrl: company.logoUrl,
                    size: 48,
                    fontSize: 18,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        company.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        // USE THIS GETTER - DO NOT ACCESS .role or use manual logic here
        company.displaySubtitle, 
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    ],
  ),
),
                  if (company.hasPin)
                    const Icon(Icons.lock_outline,
                        size: 18, color: Colors.grey),
                  const SizedBox(width: 18),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  else
                    Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No companies found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new one to get started!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong.',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCompanies,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

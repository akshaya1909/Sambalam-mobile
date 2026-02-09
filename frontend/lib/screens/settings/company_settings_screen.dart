import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'company_details_screen.dart';
import '../settings/sub_screens/branches_screen.dart';
import '../settings/sub_screens/departments_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/company_api_service.dart';

class CompanySettingsScreen extends StatefulWidget {

  const CompanySettingsScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  String _companyCode = "Loading...";
  bool _isLoading = true;
  final CompanyApiService _apiService = CompanyApiService();

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String companyId = prefs.getString('companyId') ?? '';

      if (companyId.isNotEmpty) {
        // Fetch basic company info from your existing API
        final companyData = await _apiService.getCompanyById(companyId);
        
        if (mounted && companyData != null) {
          setState(() {
            _companyCode = companyData.companyCode ?? 'N/A'; // Assuming your model uses companyCode
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading company code: $e");
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(BuildContext context) {
  // 1. Prevent copying if the code hasn't loaded yet
  if (_isLoading || _companyCode == "Loading..." || _companyCode == "N/A") {
    return; 
  }

  // 2. Use Clipboard.setData to push the string to the system clipboard
  Clipboard.setData(ClipboardData(text: _companyCode)).then((_) {
    // 3. Show a toast/snackbar to confirm to the user it worked
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Company code $_companyCode copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF206C5E), // Using your primary color
          duration: const Duration(seconds: 2),
        ),
      );
    }
  });
}

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF206C5E);
    const Color bg = Color(0xFFF3F4F6);
    const Color cardBg = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        centerTitle: false,
        titleSpacing: 0,

        // --- FIX STARTS HERE ---
        // 1. Force all icons (leading & actions) to be black
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        // 2. Force the title text to be black
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        // --- FIX ENDS HERE ---

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Company settings',
          // Note: You don't need to repeat fontSize/weight here if you set it in titleTextStyle above,
          // but keeping it is fine. The color from titleTextStyle will apply automatically.
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.domain_verification_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Organisation overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Manage your company profile, branches and departments in one place.',
                            style: TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 12,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Content cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _SectionLabel(text: 'COMPANY'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _CompanyItemTile(
                        icon: Icons.apartment_outlined,
                        title: 'Company details',
                        subtitle: 'Legal name, address, GST & branding',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CompanyDetailsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel(text: 'STRUCTURE'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _CompanyItemTile(
                        icon: Icons.account_tree_outlined,
                        title: 'My branches',
                        subtitle: 'Create and manage office locations',
                        onTap: () {
                          // Navigate to BranchesScreen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BranchesScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _CompanyItemTile(
                        icon: Icons.account_tree_rounded,
                        title: 'My departments',
                        subtitle: 'Organise teams and reporting lines',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const DepartmentsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Company code footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_outlined,
                    size: 22,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Company code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _isLoading 
            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(
                _companyCode,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: 0.9),
              ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _copyToClipboard(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.handshake_outlined), label: 'CRM'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        currentIndex: 2,
        onTap: (idx) {
          if (idx == 0) {
            Navigator.of(context).pop();
          } else if (idx == 1) {
            // TODO: open CRM
          }
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(children: children),
    );
  }
}

class _CompanyItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _CompanyItemTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

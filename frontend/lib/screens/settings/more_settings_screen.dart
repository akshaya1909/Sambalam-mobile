import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../auth/login/login_screen.dart';
import '../settings/sub_screens/select_company_modal.dart';
import '../terms_and_condition/privacy_policy_screen.dart';
import '../terms_and_condition/terms_and_conditions_screen.dart';
import '../../api/company_settings_api_service.dart';

class MoreSettingsScreen extends StatefulWidget {
  const MoreSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MoreSettingsScreen> createState() => _MoreSettingsScreenState();
}

class _MoreSettingsScreenState extends State<MoreSettingsScreen> {
  static const String _baseUrl =
      'https://sambalam.ifoxclicks.com'; // adjust for env
  String? _companyCode;
  bool _loadingCode = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyCode();
  }

  Future<void> _loadCompanyCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');
      if (companyId == null) {
        setState(() {
          _companyCode = null;
          _loadingCode = false;
        });
        return;
      }

      final uri = Uri.parse('$_baseUrl/api/company/basic/$companyId');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          _companyCode = data['company_code'] as String?;
          _loadingCode = false;
        });
      } else {
        setState(() {
          _companyCode = null;
          _loadingCode = false;
        });
      }
    } catch (_) {
      setState(() {
        _companyCode = null;
        _loadingCode = false;
      });
    }
  }

  Future<void> _clearAllAndLogout(
      BuildContext context, BuildContext dialogCtx) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Capture the onboarding status (using the key WITHOUT 'flutter.' prefix)
    final bool isOnboardingComplete =
        prefs.getBool('onboarding_complete') ?? false;

    // 2. Clear all data
    await prefs.clear();

    // 3. Restore the onboarding status
    // The plugin will automatically save this as 'flutter.onboarding_complete' in the background
    if (isOnboardingComplete) {
      await prefs.setBool('onboarding_complete', true);
    }

    if (!mounted) return;

    Navigator.of(dialogCtx).pop();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    const Color primaryRed = Color(0xFFDC2626);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.86,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Are you sure you want to logout from this device?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _clearAllAndLogout(context, ctx),
                          child: const Text(
                            'Yes, logout',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color headerBg = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: headerBg,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'More settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _headerCard(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _sectionLabel('General'),
                  _settingsCard(
                    children: [
                      _SettingsTileNew(
                        icon: Icons.lightbulb_outline,
                        title: 'Request a feature',
                        subtitle: 'Tell us what you want to see next',
                        color: const Color(0xFFF59E0B),
                        onTap: () async {
                          // Replace this with your actual Google Form "Send" link
                          final Uri formUri = Uri.parse(
                              "https://docs.google.com/forms/d/e/1FAIpQLScMgBan4ltsI0JXO5pxTTDL2R9h0h_Elg7UaoS8UDtYqjPIwQ/viewform?usp=publish-editor");

                          try {
                            if (await canLaunchUrl(formUri)) {
                              await launchUrl(
                                formUri,
                                // LaunchMode.externalApplication ensures it opens in the
                                // default browser or the Google Forms app if installed.
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              throw 'Could not launch $formUri';
                            }
                          } catch (e) {
                            // Show a snackbar if the link fails to open
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Could not open the request form: $e")),
                            );
                          }
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.list_alt_outlined,
                        title: 'Select company',
                        subtitle: 'Switch between multiple companies',
                        color: const Color(0xFF3B82F6),
                        onTap: () async {
                          // 1. Show a loading indicator so user knows something is happening
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final userId = prefs.getString('userId');
                            final CompanySettingsApiService api =
                                CompanySettingsApiService();

                            // 2. Fetch data before showing the popup
                            final phone = await api.getUserPhone(userId!);
                            final companies = await api.getUserCompanies(phone);

                            // Dismiss the loading indicator
                            if (context.mounted) Navigator.pop(context);

                            // 3. Logic Check: Show Snackbar if empty, otherwise show Modal
                            if (companies.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No other companies found for selection'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => const SelectCompanyModal(),
                                );
                              }
                            }
                          } catch (e) {
                            // Dismiss loading on error
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Failed to load companies')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Legal & privacy'),
                  _settingsCard(
                    children: [
                      _SettingsTileNew(
                        icon: Icons.description_outlined,
                        title: 'Terms & conditions',
                        subtitle: 'Usage terms for this application',
                        color: const Color(0xFF6366F1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TermsAndConditionsScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.lock_outline,
                        title: 'Privacy policy',
                        subtitle: 'How your data is stored and used',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Account'),
                  _settingsCard(
                    children: [
                      _SettingsTileNew(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out from this device',
                        color: const Color(0xFFDC2626),
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _companyCodeCard(),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'v 6.73',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF1F2937),
              child: Icon(
                Icons.tune_outlined,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage additional preferences, legal pages and logout.',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _companyCodeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              children: [
                const TextSpan(text: 'Company code: '),
                TextSpan(
                  text: _loadingCode ? 'Loading...' : (_companyCode ?? 'N/A'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
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

class _SettingsTileNew extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _SettingsTileNew({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF9CA3AF),
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.4),
      ],
    );
  }
}

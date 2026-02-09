import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login/login_screen.dart';
import '../../models/company_model.dart';
import '../settings/sub_screens/select_company_modal.dart';
import '../../api/company_settings_api_service.dart';
import '../terms_and_condition/terms_and_conditions_screen.dart';
import '../terms_and_condition/privacy_policy_screen.dart';

class MoreAdminSettingsScreen extends StatefulWidget {
  const MoreAdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MoreAdminSettingsScreen> createState() =>
      _MoreAdminSettingsScreenState();
}

class _MoreAdminSettingsScreenState extends State<MoreAdminSettingsScreen> {
  final CompanySettingsApiService _settingsApi = CompanySettingsApiService();
  static const String _baseUrl = 'https://sambalam.ifoxclicks.com'; // adjust
  bool _appNotifications = true;
  String? _companyCode;
  bool _loadingCode = true;

  Future<void> _handleDeleteAllStaff() async {
    // 1. Get Company ID
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyId');

    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company ID not found')),
      );
      return;
    }

    // 2. Show Danger Dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Delete All Staff?',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'This action is IRREVERSIBLE.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 8),
            Text(
              'All employee records, including attendance history, leave balances, and bank details will be permanently erased.',
              style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
            SizedBox(height: 8),
            Text(
              'Are you absolutely sure you want to proceed?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 3. Call API
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: Colors.red)),
      );

      await _settingsApi.deleteAllStaff(companyId);

      // Hide loading
      if (mounted) Navigator.pop(context);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All staff records deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadCompanyCode(),
      _loadNotificationPref(),
    ]);
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('app_notifications') ?? true;
    setState(() {
      _appNotifications = value;
    });
  }

  Future<void> _saveNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_notifications', value);
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

  Future<void> _clearAllExceptOnboarding(
      BuildContext context, BuildContext dialogCtx) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get the current status using the standard key (no 'flutter.' prefix)
    final bool keepOnboarding = prefs.getBool('onboarding_complete') ?? false;

    // 2. Clear everything
    await prefs.clear();

    // 3. Restore ONLY the onboarding status using the standard key
    // The plugin will handle adding the 'flutter.' prefix internally.
    if (keepOnboarding) {
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
                    'Are you sure you want to logout from this application?',
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
                          onPressed: () =>
                              _clearAllExceptOnboarding(context, ctx),
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
    const Color accent = Color(0xFF2563EB);

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
                  _sectionLabel('Notifications'),
                  _notificationCard(accent),
                  const SizedBox(height: 16),
                  _sectionLabel('Others'),
                  _settingsCard(
                    children: [
                      _SettingsTileNew(
                        icon: Icons.thumb_up_alt_outlined,
                        title: 'Rate us',
                        subtitle: 'Share your experience on the store',
                        color: const Color(0xFFF59E0B),
                        onTap: () async {
                          // Replace with your actual package name from android/app/build.gradle
                          const packageName = "com.sambalam.app";

                          // market:// triggers the Play Store app directly
                          // https:// version is a fallback for web/other platforms
                          final Uri playStoreUri =
                              Uri.parse("market://details?id=$packageName");
                          final Uri webFallbackUri = Uri.parse(
                              "https://play.google.com/store/apps/details?id=$packageName");

                          try {
                            if (await canLaunchUrl(playStoreUri)) {
                              await launchUrl(playStoreUri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              // Fallback for devices without Play Store app (like some tablets)
                              await launchUrl(webFallbackUri,
                                  mode: LaunchMode.externalApplication);
                            }
                          } catch (e) {
                            debugPrint("Could not launch Play Store: $e");
                          }
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.lightbulb_outline,
                        title: 'Request a feature',
                        subtitle: 'Suggest improvements and new ideas',
                        color: const Color(0xFF10B981),
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
                        subtitle: 'Switch between companies',
                        color: const Color(0xFF3B82F6),
                        onTap: () async {
                          // 1. Show a transparent loading overlay so the user knows data is being fetched
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                          );

                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final userId = prefs.getString('userId');
                            if (userId == null)
                              throw Exception('User not logged in');
                            final String? currentCompanyId =
                                prefs.getString('companyId')?.toString();
                            final CompanySettingsApiService api =
                                CompanySettingsApiService();

                            if (userId == null)
                              throw Exception('User not logged in');

                            // 2. Fetch the phone number and then the company list
                            final phone = await api.getUserPhone(userId);
                            final List<Company> allCompanies =
                                await api.getUserCompanies(phone);

                            if (mounted) Navigator.pop(context);

                            // if (allCompanies is! List) {
                            //   debugPrint(
                            //       "Expected List but got: ${allCompanies.runtimeType}");
                            // }

                            // 4. Conditional Logic: Show Snackbar if empty, otherwise show Popup
                            if (allCompanies.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No other companies found for selection'),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => SelectCompanyModal(),
                                );
                              }
                            }
                          } catch (e) {
                            // Close loading dialog on error
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: ${e.toString()}')),
                              );
                            }
                          }
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.refresh_outlined,
                        title: 'Delete all staff',
                        subtitle: 'Remove all staff records for this company',
                        color: const Color(0xFFDC2626),
                        isDestructive: true,
                        onTap:
                            _handleDeleteAllStaff, // <--- Connect Handler Here
                      ),
                      _SettingsTileNew(
                        icon: Icons.description_outlined,
                        title: 'Terms & conditions',
                        subtitle: 'View terms of use',
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
//                         onTap: () async {
//   final Uri url = Uri.parse("https://sambalam.ifoxclicks.com/terms");
//   if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
//     throw 'Could not launch $url';
//   }
// },
                      ),
                      _SettingsTileNew(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy policy',
                        subtitle: 'Understand how data is used',
                        color: const Color(0xFF0EA5E9),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out from this device',
                        color: const Color(0xFFDC2626),
                        isDestructive: true,
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _companyCodeCard(),
                  const SizedBox(height: 12),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        'v 6.73',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
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
                    'More admin settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Control notifications, legal pages and account actions.',
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

  Widget _notificationCard(Color accent) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _appNotifications
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App notifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Receive alerts about staff activity and approvals.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _appNotifications,
              activeColor: Colors.white,
              activeTrackColor: accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE5E7EB),
              onChanged: (val) {
                setState(() {
                  _appNotifications = val;
                });
                _saveNotificationPref(val);
              },
            ),
          ],
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
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingsTileNew({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isDestructive = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        isDestructive ? const Color(0xFFB91C1C) : Colors.black87;

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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
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

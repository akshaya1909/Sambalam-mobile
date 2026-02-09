import 'package:flutter/material.dart';

class AdditionalSettingsScreen extends StatefulWidget {
  final String employeeName;
  final String employeeId;

  const AdditionalSettingsScreen({
    Key? key,
    required this.employeeName,
    required this.employeeId,
  }) : super(key: key);

  @override
  State<AdditionalSettingsScreen> createState() =>
      _AdditionalSettingsScreenState();
}

class _AdditionalSettingsScreenState extends State<AdditionalSettingsScreen> {
  // Theme colors matching your Admin and Penalty screens
  final Color primaryDeepTeal = const Color(0xFF064E3B);
  final Color primaryTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color scaffoldBg = const Color(0xFFF4F6FB);

  // Example State variables
  String _selectedTimezone = "(GMT+05:30) India Standard Time";
  String _selectedLanguage = "English (India)";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Gradient Header matching Penalty & Overtime screen
          SliverAppBar(
            expandedHeight: 160.0,
            pinned: true,
            elevation: 0,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryDeepTeal, primaryTeal, secondaryTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employeeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Regional Settings",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel("Preferences"),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.language_rounded,
                      title: "App Language",
                      value: _selectedLanguage,
                      onTap: () => _showLanguagePicker(),
                    ),
                    _buildSettingsTile(
                      icon: Icons.public_rounded,
                      title: "Timezone",
                      value: _selectedTimezone,
                      onTap: () => _showTimezonePicker(),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionLabel("System Access"),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.phonelink_setup_rounded,
                      title: "Device Binding",
                      value: "Single Device Active",
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.history_rounded,
                      title: "Login Activity",
                      value: "View History",
                      onTap: () {},
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: secondaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryTeal, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  // --- PLACEHOLDER PICKERS ---
  void _showLanguagePicker() {
    // Implement your language selection logic here
  }

  void _showTimezonePicker() {
    // Implement your timezone selection logic here
  }
}

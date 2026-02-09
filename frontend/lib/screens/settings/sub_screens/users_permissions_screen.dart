import 'package:flutter/material.dart';
import 'admins_screen.dart';
import '../../employee/employee_managers_screen.dart';

class UsersPermissionsScreen extends StatelessWidget {
  const UsersPermissionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF3F4F6);
    const Color cardBg = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Users & permissions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header Card (Matching Company Settings Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4F46E5),
                      Color(0xFF818CF8)
                    ], // Indigo Gradient
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Roles',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Manage access levels for your team and external accountants.',
                            style: TextStyle(
                              color: Color(0xFFE0E7FF),
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

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const _SectionLabel(text: 'ROLES & ACCESS'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _UserItemTile(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFFDC2626),
                        iconBg: const Color(0xFFFEE2E2),
                        title: 'Admins',
                        subtitle: 'Full access to all settings & data',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AdminsScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _UserItemTile(
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFF059669),
                        iconBg: const Color(0xFFD1FAE5),
                        title: 'Employees & managers',
                        subtitle: 'Manage staff, attendance & CRM access',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EmployeeManagersScreen()),
                          );
                        },
                      ),
                      // const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      // _UserItemTile(
                      //   icon: Icons.calculate_outlined,
                      //   iconColor:
                      //       const Color(0xFFD97706), // Amber for Accountant
                      //   iconBg: const Color(0xFFFEF3C7),
                      //   title: 'Chartered accountant',
                      //   subtitle: 'Read-only access for audits & tax',
                      //   onTap: () {
                      //     // TODO: Navigate to CA Settings
                      //   },
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Local Widgets (Replicated to ensure standalone functionality) ---

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

class _UserItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  const _UserItemTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 3),
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
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

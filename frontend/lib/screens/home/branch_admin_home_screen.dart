import 'package:flutter/material.dart';
// Import all your existing screens here
import 'admin_home_screen.dart';
import '../admin/crm_screen.dart';
import 'employee_home_screen.dart'; // This is the "Mark Attendance" screen
import '../profile/profile_screen.dart';
import '../settings/admin_settings_screen.dart';

class BranchAdminHomeScreen extends StatefulWidget {
  final String phoneNumber;
  final String companyId;
  final List<String> allowedBranchIds;

  const BranchAdminHomeScreen({
    Key? key,
    required this.phoneNumber,
    required this.companyId,
    required this.allowedBranchIds,
  }) : super(key: key);

  @override
  State<BranchAdminHomeScreen> createState() => _BranchAdminHomeScreenState();
}

class _BranchAdminHomeScreenState extends State<BranchAdminHomeScreen> {
  int _currentIndex = 0;

  // This list maps the bottom nav icons to your existing screens
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // 1. HOME (Admin Overview)
      AdminHomeScreen(
        phoneNumber: widget.phoneNumber,
        role: 'branch admin',
        allowedBranchIds: widget.allowedBranchIds,
        hideInternalNav: true,
        onAddStaff: () {}, // Add logic or leave empty
        onInviteStaff: () {},
        onReports: () {},
        onEditAttendance: () {},
        onHelp: () {},
      ),
      // 2. CRM
      const CRMScreen(),
      // 3. MARK ATTENDANCE (The Employee Home Screen)
      EmployeeHomeScreen(
        phoneNumber: widget.phoneNumber,
        companyId: widget.companyId,
        hideInternalNav: true,
      ),
      // 4. PROFILE
      ProfileScreen(
        phoneNumber: widget.phoneNumber,
        companyId: widget.companyId,
        hideInternalNav: true,
      ),
      // 5. SETTINGS
      const AdminSettingsScreen(
        hideInternalNav: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF206C5E);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Necessary for 5 items
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.handshake_outlined), label: 'CRM'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint), label: 'Mark Attendance'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
// Import your existing screens
import '../attendance/daily_attendance_screen.dart'; // Staff Attendance
import '../home/employee_home_screen.dart'; // My Attendance
import '../profile/profile_screen.dart'; // Profile
import '../settings/admin_settings_screen.dart'; // Settings

class AttendanceManagerHomeScreen extends StatefulWidget {
  final String phoneNumber;
  final String companyId;

  const AttendanceManagerHomeScreen({
    Key? key,
    required this.phoneNumber,
    required this.companyId,
  }) : super(key: key);

  @override
  State<AttendanceManagerHomeScreen> createState() =>
      _AttendanceManagerHomeScreenState();
}

class _AttendanceManagerHomeScreenState
    extends State<AttendanceManagerHomeScreen> {
  int _currentIndex = 0;

  // The order defined: Staff, My Attendance, Profile, Settings
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // 1. STAFF (Daily Attendance Screen)
      DailyAttendanceScreen(
        initialFilter: AttendanceFilter.all,
        companyId: widget.companyId,
        // hideInternalNav: true, // Hide its internal bar
      ),

      // 2. MY ATTENDANCE (Employee Home Screen)
      EmployeeHomeScreen(
        phoneNumber: widget.phoneNumber,
        companyId: widget.companyId,
        hideInternalNav: true, // Hide its internal bar
      ),

      // 3. PROFILE
      ProfileScreen(
        phoneNumber: widget.phoneNumber,
        companyId: widget.companyId,
        hideInternalNav: true, // Hide its internal bar
      ),

      // 4. SETTINGS
      AdminSettingsScreen(
        hideInternalNav: true, // Hide its internal bar
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF206C5E);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'My Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

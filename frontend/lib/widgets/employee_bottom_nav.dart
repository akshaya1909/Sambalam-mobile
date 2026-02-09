// lib/ui/widgets/employee_bottom_nav.dart
import 'package:flutter/material.dart';

class EmployeeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Color activeColor;
  final Color inactiveColor;

  const EmployeeBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.activeColor,
    this.inactiveColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8, top: 6, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.fingerprint,
            label: 'Mark Attendance',
            isActive: selectedIndex == 0,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            onTap: () => onItemSelected(0),
          ),
          _BottomNavItem(
            icon: Icons.beach_access_outlined,
            label: 'Leaves',
            isActive: selectedIndex == 1,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            onTap: () => onItemSelected(1),
          ),
          _BottomNavItem(
            icon: Icons.person,
            label: 'Profile',
            isActive: selectedIndex == 2,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            onTap: () => onItemSelected(2),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _BottomNavItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

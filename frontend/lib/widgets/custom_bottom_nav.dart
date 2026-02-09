import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final double iconSize;
  final double height;
  
  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8.0,
    this.iconSize = 24.0,
    this.height = 60.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (index) => _buildNavItem(index),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = items[index];
    final isSelected = index == currentIndex;
    
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon ?? item.icon : item.icon,
              color: isSelected
                  ? selectedItemColor ?? AppTheme.primaryColor
                  : unselectedItemColor ?? AppTheme.textSecondaryColor,
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? selectedItemColor ?? AppTheme.primaryColor
                    : unselectedItemColor ?? AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final bool showBadge;
  final String? badgeText;
  
  const BottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.showBadge = false,
    this.badgeText,
  });
}

class CustomBottomNavBarWithFab extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Widget fab;
  final VoidCallback onFabPressed;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final double iconSize;
  final double height;
  
  const CustomBottomNavBarWithFab({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.fab,
    required this.onFabPressed,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8.0,
    this.iconSize = 24.0,
    this.height = 60.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: elevation,
                spreadRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length + 1, // +1 for the empty space in the middle
              (index) {
                if (index == items.length ~/ 2) {
                  // Empty space for FAB
                  return const SizedBox(width: 80);
                }
                
                final itemIndex = index > items.length ~/ 2 ? index - 1 : index;
                return _buildNavItem(itemIndex);
              },
            ),
          ),
        ),
        Positioned(
          top: -20,
          child: GestureDetector(
            onTap: onFabPressed,
            child: fab,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index) {
    final item = items[index];
    final isSelected = index == currentIndex;
    
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon ?? item.icon : item.icon,
              color: isSelected
                  ? selectedItemColor ?? AppTheme.primaryColor
                  : unselectedItemColor ?? AppTheme.textSecondaryColor,
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? selectedItemColor ?? AppTheme.primaryColor
                    : unselectedItemColor ?? AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
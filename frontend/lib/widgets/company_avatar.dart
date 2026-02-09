import 'package:flutter/material.dart';

class CompanyAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double? fontSize; // 1. Add this field

  const CompanyAvatar({
    Key? key,
    required this.name,
    this.size = 48,
    this.fontSize, // 2. Add this to constructor
  }) : super(key: key);

  static const List<Color> _colors = [
    Color(0xFF8B4513),
    Color(0xFF6A0DAD),
    Color(0xFF1E90FF),
    Color(0xFF228B22),
    Color(0xFFFF4500),
    Color(0xFFFF1493),
  ];

  Color _getColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final index = name.codeUnitAt(0) % _colors.length;
    return _colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bgColor = _getColor(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            // 3. Use fontSize if provided, otherwise fallback to auto-calculation
            fontSize: fontSize ?? (size * 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

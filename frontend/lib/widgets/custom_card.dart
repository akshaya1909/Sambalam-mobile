import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool hasBorder;
  final Color? borderColor;
  final double? width;
  final double? height;
  
  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius = AppConstants.cardBorderRadius,
    this.backgroundColor,
    this.onTap,
    this.hasBorder = false,
    this.borderColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: borderColor ?? AppTheme.dividerColor,
                width: 1.0,
              )
            : null,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: elevation! * 2,
                  spreadRadius: elevation! * 0.2,
                  offset: Offset(0, elevation! * 0.5),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: card,
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool hasBadge;
  final String? badgeText;
  
  const ActionCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    required this.onTap,
    this.trailing,
    this.hasBadge = false,
    this.badgeText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (backgroundColor ?? AppTheme.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Stack(
                  children: [
                    Icon(
                      icon,
                      color: iconColor ?? backgroundColor ?? AppTheme.primaryColor,
                      size: 24,
                    ),
                    if (hasBadge)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.errorColor,
                            shape: BoxShape.circle,
                          ),
                          child: badgeText != null
                              ? Text(
                                  badgeText!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const SizedBox(
                                  width: 4,
                                  height: 4,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const StatusCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (backgroundColor ?? AppTheme.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? backgroundColor ?? AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
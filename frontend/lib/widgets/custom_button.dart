import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.borderRadius = 8.0,
    this.padding,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppTheme.primaryColor,
            side: BorderSide(color: backgroundColor ?? AppTheme.primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppTheme.primaryColor,
            foregroundColor: textColor ?? Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          );

    final buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? (textColor ?? AppTheme.primaryColor) : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixIcon != null) ...[prefixIcon!, const SizedBox(width: 8)],
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isOutlined
                      ? (textColor ?? AppTheme.primaryColor)
                      : (textColor ?? Colors.white),
                ),
              ),
              if (suffixIcon != null) ...[const SizedBox(width: 8), suffixIcon!],
            ],
          );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonChild,
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: button,
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final bool isOutlined;
  final String? tooltip;

  const CustomIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.isOutlined = false,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppTheme.primaryColor;
    final effectiveIconColor = iconColor ?? (isOutlined ? effectiveBackgroundColor : Colors.white);

    final Widget buttonWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : effectiveBackgroundColor,
        border: isOutlined ? Border.all(color: effectiveBackgroundColor, width: 1.5) : null,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: effectiveIconColor, size: iconSize),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: size, height: size),
        splashRadius: size / 2,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
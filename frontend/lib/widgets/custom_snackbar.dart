import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIconForType(type),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _getColorForType(type),
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
      action: action,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      action: action,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
      action: action,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
      action: action,
    );
  }

  static IconData _getIconForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle;
      case SnackBarType.error:
        return Icons.error;
      case SnackBarType.warning:
        return Icons.warning;
      case SnackBarType.info:
        return Icons.info;
    }
  }

  static Color _getColorForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppTheme.successColor;
      case SnackBarType.error:
        return AppTheme.errorColor;
      case SnackBarType.warning:
        return AppTheme.warningColor;
      case SnackBarType.info:
        return AppTheme.infoColor;
    }
  }
}

enum SnackBarType {
  success,
  error,
  warning,
  info,
}
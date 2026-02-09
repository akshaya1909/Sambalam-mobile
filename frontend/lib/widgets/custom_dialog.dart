import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'custom_button.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? positiveButtonText;
  final String? negativeButtonText;
  final VoidCallback? onPositivePressed;
  final VoidCallback? onNegativePressed;
  final Widget? icon;
  final Color? iconBackgroundColor;
  
  const CustomDialog({
    Key? key,
    required this.title,
    required this.message,
    this.positiveButtonText,
    this.negativeButtonText,
    this.onPositivePressed,
    this.onNegativePressed,
    this.icon,
    this.iconBackgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[_buildIconHeader(), const SizedBox(height: 16)],
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildButtons(context),
        ],
      ),
    );
  }

  Widget _buildIconHeader() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: iconBackgroundColor ?? AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(child: icon),
    );
  }

  Widget _buildButtons(BuildContext context) {
    if (negativeButtonText == null) {
      return CustomButton(
        text: positiveButtonText ?? 'OK',
        onPressed: onPositivePressed ?? () => Navigator.of(context).pop(),
      );
    }

    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: negativeButtonText!,
            onPressed: onNegativePressed ?? () => Navigator.of(context).pop(),
            isOutlined: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: positiveButtonText ?? 'OK',
            onPressed: onPositivePressed ?? () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;
  
  const SuccessDialog({
    Key? key,
    this.title = 'Success',
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      message: message,
      positiveButtonText: buttonText,
      onPositivePressed: onPressed,
      icon: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
      iconBackgroundColor: AppTheme.successColor.withOpacity(0.1),
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;
  
  const ErrorDialog({
    Key? key,
    this.title = 'Error',
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      message: message,
      positiveButtonText: buttonText,
      onPositivePressed: onPressed,
      icon: const Icon(Icons.error, color: AppTheme.errorColor, size: 32),
      iconBackgroundColor: AppTheme.errorColor.withOpacity(0.1),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String positiveButtonText;
  final String negativeButtonText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  
  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.positiveButtonText = 'Yes',
    this.negativeButtonText = 'No',
    required this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      message: message,
      positiveButtonText: positiveButtonText,
      negativeButtonText: negativeButtonText,
      onPositivePressed: onConfirm,
      onNegativePressed: onCancel ?? () => Navigator.of(context).pop(),
      icon: const Icon(Icons.help, color: AppTheme.warningColor, size: 32),
      iconBackgroundColor: AppTheme.warningColor.withOpacity(0.1),
    );
  }
}

// Helper functions to show dialogs
class DialogHelper {
  static Future<void> showSuccessDialog({
    required BuildContext context,
    String title = 'Success',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SuccessDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
        );
      },
    );
  }

  static Future<void> showErrorDialog({
    required BuildContext context,
    String title = 'Error',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ErrorDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
        );
      },
    );
  }

  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String positiveButtonText = 'Yes',
    String negativeButtonText = 'No',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: title,
          message: message,
          positiveButtonText: positiveButtonText,
          negativeButtonText: negativeButtonText,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );
    return result ?? false;
  }
}
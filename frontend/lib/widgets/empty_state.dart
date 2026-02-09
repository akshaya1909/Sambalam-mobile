import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'custom_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double iconSize;
  final Color? iconColor;
  
  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
    this.iconSize = 80,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppTheme.textLightColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[  
              const SizedBox(height: 24),
              CustomButton(
                text: buttonText!,
                onPressed: onButtonPressed!,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoDataFound extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const NoDataFound({
    Key? key,
    this.message = 'No data found',
    this.buttonText,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No Data',
      message: message,
      icon: Icons.inbox,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const ErrorState({
    Key? key,
    this.message = 'Something went wrong',
    this.buttonText = 'Try Again',
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'Error',
      message: message,
      icon: Icons.error_outline,
      iconColor: AppTheme.errorColor,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
}

class NoInternetState extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const NoInternetState({
    Key? key,
    this.message = 'No internet connection',
    this.buttonText = 'Retry',
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No Internet',
      message: message,
      icon: Icons.wifi_off,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
}

class NoResultsFound extends StatelessWidget {
  final String searchTerm;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const NoResultsFound({
    Key? key,
    required this.searchTerm,
    this.buttonText = 'Clear Search',
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No Results Found',
      message: 'We couldn\'t find any results for "$searchTerm"',
      icon: Icons.search_off,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
}
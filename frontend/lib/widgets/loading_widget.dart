import 'package:flutter/material.dart';
import '../utils/theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isFullScreen;
  
  const LoadingWidget({
    Key? key,
    this.message,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loadingWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
    
    if (isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: loadingWidget),
      );
    }
    
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: loadingWidget,
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;

  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: LoadingWidget(message: loadingMessage),
          ),
      ],
    );
  }
}
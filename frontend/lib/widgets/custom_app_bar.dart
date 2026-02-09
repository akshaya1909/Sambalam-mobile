import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? titleColor;
  final double elevation;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final Widget? titleWidget;
  final PreferredSizeWidget? bottom;
  
  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.titleColor,
    this.elevation = 0,
    this.onBackPressed,
    this.centerTitle = true,
    this.titleWidget,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      elevation: elevation,
      leading: showBackButton
          ? leading ?? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : leading,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? kToolbarHeight : kToolbarHeight + bottom!.preferredSize.height);
}

class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backButtonColor;
  final VoidCallback? onBackPressed;
  
  const TransparentAppBar({
    Key? key,
    this.showBackButton = true,
    this.actions,
    this.backButtonColor,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: backButtonColor ?? Colors.black,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? titleColor;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final bool pinned;
  final bool floating;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  
  const CustomSliverAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.titleColor,
    this.expandedHeight = 200.0,
    this.flexibleSpace,
    this.pinned = true,
    this.floating = false,
    this.onBackPressed,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      leading: showBackButton
          ? leading ?? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : leading,
      actions: actions,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace,
      pinned: pinned,
      floating: floating,
    );
  }
}
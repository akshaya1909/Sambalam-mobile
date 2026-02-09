import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF1E88E5); // Blue
  static const Color primaryLightColor = Color(0xFF6AB7FF);
  static const Color primaryDarkColor = Color(0xFF005CB2);
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFF26A69A); // Teal
  static const Color secondaryLightColor = Color(0xFF64D8CB);
  static const Color secondaryDarkColor = Color(0xFF00766C);
  
  // Background colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color scaffoldBackgroundColor = Color(0xFFF5F5F5);
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);
  
  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFB300);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Other colors
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color disabledColor = Color(0xFFBDBDBD);
  
  // Get the theme data
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      primaryColorLight: primaryLightColor,
      primaryColorDark: primaryDarkColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        background: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      disabledColor: disabledColor,
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        hintStyle: const TextStyle(color: textLightColor),
        errorStyle: const TextStyle(color: errorColor, fontSize: 12),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimaryColor, fontSize: 28, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimaryColor, fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textSecondaryColor, fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: textPrimaryColor, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(color: textSecondaryColor, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: textPrimaryColor, fontSize: 14, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: textSecondaryColor, fontSize: 12, fontWeight: FontWeight.normal),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryLightColor.withOpacity(0.2),
        disabledColor: disabledColor.withOpacity(0.2),
        selectedColor: primaryColor.withOpacity(0.2),
        secondarySelectedColor: secondaryColor.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(color: textPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Tab bar theme
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
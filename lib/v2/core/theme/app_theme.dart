import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Color scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryGreen,
        primaryContainer: AppColors.primaryGreenLight,
        secondary: AppColors.goldAccent,
        background: AppColors.scaffoldBackground,
        surface: AppColors.cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.scaffoldBackground,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white, size: 24),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textHint,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodySmall,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
      ),
    );
  }
}

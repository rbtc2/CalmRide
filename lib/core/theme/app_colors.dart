import 'package:flutter/material.dart';

/// CalmRide 앱의 색상 팔레트
/// 멀미 완화에 효과적인 차분한 색상들을 사용
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors - 멀미 완화에 효과적인 청록색 계열
  static const Color primaryMint = Color(0xFF4ECDC4);
  static const Color primaryBlue = Color(0xFF45B7D1);
  static const Color primaryTeal = Color(0xFF26A69A);

  // Secondary Colors
  static const Color secondaryGray = Color(0xFF78909C);
  static const Color secondaryLightGray = Color(0xFFB0BEC5);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Stabilization Colors - 멀미 방지에 효과적인 색상들
  static const Color stabilizationDot = Color(0xFF4ECDC4);
  static const Color stabilizationLine = Color(0xFF26A69A);
  static const Color stabilizationBackground = Color(0x1A4ECDC4);

  // Pro Mode Colors
  static const Color proGold = Color(0xFFFFD700);
  static const Color proGradientStart = Color(0xFFFFD700);
  static const Color proGradientEnd = Color(0xFFFFA000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMint, primaryBlue],
  );

  static const LinearGradient proGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [proGradientStart, proGradientEnd],
  );

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
}

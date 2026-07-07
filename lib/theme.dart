import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF5B6AF0);
  static const accent = Color(0xFFF4A261);
  static const background = Color(0xFFF8F9FF);
  static const textDark = Color(0xFF1A1A2E);
  static const success = Color(0xFF2EC4B6);
  static const danger = Color(0xFFE63946);
  static const warning = Color(0xFFFFB703);
  static const frozen = Color(0xFF90CAF9);
  static const abandoned = Color(0xFFBDBDBD);
  static const cardWhite = Color(0xFFFFFFFF);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleMedium: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 16,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14,
          color: textDark,
        ),
        bodySmall: GoogleFonts.notoSans(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  static Color planStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'PlanStatus.comfortable': return success;
      case 'PlanStatus.onTrack': return primary;
      case 'PlanStatus.safe': return primary;
      case 'PlanStatus.danger': return warning;
      case 'PlanStatus.needsReview': return accent;
      case 'PlanStatus.difficult': return danger;
      default: return Colors.grey;
    }
  }

  static String planStatusLabel(dynamic status) {
    switch (status.toString()) {
      case 'PlanStatus.comfortable': return '余裕';
      case 'PlanStatus.onTrack': return '順調';
      case 'PlanStatus.safe': return '安全';
      case 'PlanStatus.danger': return '危険';
      case 'PlanStatus.needsReview': return '見直し要請';
      case 'PlanStatus.difficult': return '達成困難';
      default: return '-';
    }
  }

  static Color budgetStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'BudgetStatus.comfortable': return success;
      case 'BudgetStatus.safe': return primary;
      case 'BudgetStatus.danger': return warning;
      case 'BudgetStatus.overBudget': return danger;
      default: return Colors.grey;
    }
  }

  static String budgetStatusLabel(dynamic status) {
    switch (status.toString()) {
      case 'BudgetStatus.comfortable': return '余裕';
      case 'BudgetStatus.safe': return '安全';
      case 'BudgetStatus.danger': return '危険';
      case 'BudgetStatus.overBudget': return '自粛要請';
      default: return '-';
    }
  }
}

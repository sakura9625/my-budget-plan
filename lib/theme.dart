import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ---- カラーパレット ----
  static const primary = Color(0xFFF5C400);
  static const primaryDark = Color(0xFFE6B800);
  static const primaryTint = Color(0x26F5C400);
  static const navy = Color(0xFF1A2B5E);
  static const background = Color(0xFF1A2B5E);   // 背景をネイビーに
  static const cardWhite = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A2B5E);
  static const textLight = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFAABBCC);    // ネイビー背景上のグレー

  // ---- ステータスカラー（段階配色：余裕=緑 → 順調/安全=黄緑 → 危険/見直し要請=オレンジ → 達成困難=赤）----
  static const success = Color(0xFF1E7A46);      // 余裕
  static const successBg = Color(0xFFE3F5EA);
  static const onTrack = Color(0xFF5A7A1E);       // 順調・安全
  static const onTrackBg = Color(0xFFEEF5DD);
  static const warning = Color(0xFFB26A00);       // 危険
  static const warningBg = Color(0xFFFCEFD9);
  static const needsReview = Color(0xFFB26A00);   // 見直し要請（危険と同トーン）
  static const needsReviewBg = Color(0xFFFCEFD9);
  static const danger = Color(0xFFB3261E);        // 達成困難
  static const dangerBg = Color(0xFFFBE3E1);

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
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
        titleLarge: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
        titleMedium: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
        bodyLarge: GoogleFonts.notoSans(
          fontSize: 16,
          color: textLight,
        ),
        bodyMedium: GoogleFonts.notoSans(
          fontSize: 14,
          color: textLight,
        ),
        bodySmall: GoogleFonts.notoSans(
          fontSize: 12,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textLight,
        titleTextStyle: GoogleFonts.notoSans(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: navy,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF243570),
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        indicatorColor: primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF243570),
        indicatorColor: primaryTint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return GoogleFonts.notoSans(
            fontSize: 12,
            color: textMuted,
          );
        }),
      ),
    );
  }

  // ---- ステータス系ヘルパー ----

  static Color planStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'PlanStatus.comfortable': return success;
      case 'PlanStatus.onTrack':     return onTrack;
      case 'PlanStatus.safe':        return onTrack;
      case 'PlanStatus.danger':      return warning;
      case 'PlanStatus.needsReview': return needsReview;
      case 'PlanStatus.difficult':   return danger;
      default: return Colors.grey;
    }
  }

  static Color planStatusBgColor(dynamic status) {
    switch (status.toString()) {
      case 'PlanStatus.comfortable': return successBg;
      case 'PlanStatus.onTrack':     return onTrackBg;
      case 'PlanStatus.safe':        return onTrackBg;
      case 'PlanStatus.danger':      return warningBg;
      case 'PlanStatus.needsReview': return needsReviewBg;
      case 'PlanStatus.difficult':   return dangerBg;
      default: return const Color(0xFFF5F5F5);
    }
  }

  static String planStatusLabel(dynamic status) {
    switch (status.toString()) {
      case 'PlanStatus.comfortable': return '余裕';
      case 'PlanStatus.onTrack':     return '順調';
      case 'PlanStatus.safe':        return '安全';
      case 'PlanStatus.danger':      return '危険';
      case 'PlanStatus.needsReview': return '見直し要請';
      case 'PlanStatus.difficult':   return '達成困難';
      default: return '-';
    }
  }

  static Color budgetStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'BudgetStatus.comfortable': return success;
      case 'BudgetStatus.safe':        return onTrack;
      case 'BudgetStatus.danger':      return warning;
      case 'BudgetStatus.overBudget':  return danger;
      default: return Colors.grey;
    }
  }

  static Color budgetStatusBgColor(dynamic status) {
    switch (status.toString()) {
      case 'BudgetStatus.comfortable': return successBg;
      case 'BudgetStatus.safe':        return onTrackBg;
      case 'BudgetStatus.danger':      return warningBg;
      case 'BudgetStatus.overBudget':  return dangerBg;
      default: return const Color(0xFFF5F5F5);
    }
  }

  static String budgetStatusLabel(dynamic status) {
    switch (status.toString()) {
      case 'BudgetStatus.comfortable': return '余裕';
      case 'BudgetStatus.safe':        return '安全';
      case 'BudgetStatus.danger':      return '危険';
      case 'BudgetStatus.overBudget':  return '自粛要請';
      default: return '-';
    }
  }

  // ---- 原資の健全性判定 ----

  static Color affordStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'AffordStatus.comfortable': return success;
      case 'AffordStatus.ok':          return onTrack;
      case 'AffordStatus.tight':       return warning;
      default: return Colors.grey;
    }
  }

  static Color affordStatusBgColor(dynamic status) {
    switch (status.toString()) {
      case 'AffordStatus.comfortable': return successBg;
      case 'AffordStatus.ok':          return onTrackBg;
      case 'AffordStatus.tight':       return warningBg;
      default: return const Color(0xFFF5F5F5);
    }
  }

  static String affordStatusLabel(dynamic status) {
    switch (status.toString()) {
      case 'AffordStatus.comfortable': return '余裕';
      case 'AffordStatus.ok':          return '確保OK';
      case 'AffordStatus.tight':       return '控えめに';
      default: return '-';
    }
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF5C400), Color(0xFFFFD740)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

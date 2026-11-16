import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/theme/keepsync_colors.dart';

/// Temas Material 3 KeepSync: producto = Ink + Volt; links = Pitch Blue.
abstract final class KeepSyncTheme {
  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: KeepSyncColors.volt,
      onPrimary: KeepSyncColors.onVolt,
      primaryContainer: const Color(0xFFE8F9A0),
      onPrimaryContainer: KeepSyncColors.ink,
      secondary: KeepSyncColors.pitchBlue,
      onSecondary: KeepSyncColors.white,
      secondaryContainer: const Color(0xFFD6E0FF),
      onSecondaryContainer: KeepSyncColors.ink,
      tertiary: KeepSyncColors.turf,
      onTertiary: KeepSyncColors.white,
      error: KeepSyncColors.flare,
      onError: KeepSyncColors.white,
      surface: KeepSyncColors.paper,
      onSurface: KeepSyncColors.ink,
      onSurfaceVariant: KeepSyncColors.mutedLight,
      outline: KeepSyncColors.borderLight,
      outlineVariant: KeepSyncColors.borderLight,
      surfaceContainerHighest: KeepSyncColors.white,
      inverseSurface: KeepSyncColors.ink,
      onInverseSurface: KeepSyncColors.paper,
      inversePrimary: KeepSyncColors.volt,
    );
    return _build(scheme, KeepSyncThemeExt.light, Brightness.light);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.dark(
      primary: KeepSyncColors.volt,
      onPrimary: KeepSyncColors.onVolt,
      primaryContainer: KeepSyncColors.ink3,
      onPrimaryContainer: KeepSyncColors.volt,
      secondary: KeepSyncColors.pitchBlue,
      onSecondary: KeepSyncColors.white,
      secondaryContainer: KeepSyncColors.ink3,
      onSecondaryContainer: KeepSyncColors.codeKeyword,
      tertiary: KeepSyncColors.turf,
      onTertiary: KeepSyncColors.white,
      error: KeepSyncColors.flare,
      onError: KeepSyncColors.white,
      surface: KeepSyncColors.ink,
      onSurface: KeepSyncColors.paper,
      onSurfaceVariant: KeepSyncColors.mutedDark,
      outline: KeepSyncColors.borderDark,
      outlineVariant: KeepSyncColors.borderDark,
      surfaceContainerHighest: KeepSyncColors.ink3,
      surfaceContainerHigh: KeepSyncColors.ink2,
      surfaceContainer: KeepSyncColors.ink2,
      surfaceContainerLow: KeepSyncColors.ink,
      inverseSurface: KeepSyncColors.paper,
      onInverseSurface: KeepSyncColors.ink,
      inversePrimary: KeepSyncColors.ink,
    );
    return _build(scheme, KeepSyncThemeExt.dark, Brightness.dark);
  }

  static ThemeData _build(
    ColorScheme scheme,
    KeepSyncThemeExt ext,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [ext],
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: isDark ? KeepSyncColors.ink : KeepSyncColors.ink,
        foregroundColor: isDark ? KeepSyncColors.paper : KeepSyncColors.white,
        iconTheme: IconThemeData(
          color: isDark ? KeepSyncColors.paper : KeepSyncColors.white,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? KeepSyncColors.paper : KeepSyncColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? KeepSyncColors.ink2 : KeepSyncColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? KeepSyncColors.borderDark : KeepSyncColors.borderLight,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KeepSyncColors.volt,
          foregroundColor: KeepSyncColors.onVolt,
          disabledBackgroundColor: KeepSyncColors.volt.withValues(alpha: 0.4),
          disabledForegroundColor: KeepSyncColors.onVolt.withValues(alpha: 0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KeepSyncColors.volt,
          foregroundColor: KeepSyncColors.onVolt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? KeepSyncColors.volt : KeepSyncColors.ink,
          side: BorderSide(
            color: isDark ? KeepSyncColors.borderDark : KeepSyncColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KeepSyncColors.pitchBlue,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KeepSyncColors.volt,
        foregroundColor: KeepSyncColors.onVolt,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? KeepSyncColors.ink2 : KeepSyncColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? KeepSyncColors.borderDark : KeepSyncColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? KeepSyncColors.borderDark : KeepSyncColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KeepSyncColors.volt, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KeepSyncColors.flare),
        ),
        labelStyle: TextStyle(
          color: isDark ? KeepSyncColors.mutedDark : KeepSyncColors.mutedLight,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? KeepSyncColors.ink3 : KeepSyncColors.paper,
        selectedColor: KeepSyncColors.volt,
        labelStyle: TextStyle(
          color: isDark ? KeepSyncColors.paper : KeepSyncColors.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: KeepSyncColors.onVolt,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: isDark ? KeepSyncColors.borderDark : KeepSyncColors.borderLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? KeepSyncColors.borderDark : KeepSyncColors.borderLight,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? KeepSyncColors.ink3 : KeepSyncColors.ink,
        contentTextStyle: const TextStyle(color: KeepSyncColors.paper),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? KeepSyncColors.ink2 : KeepSyncColors.white,
        selectedItemColor: KeepSyncColors.volt,
        unselectedItemColor:
            isDark ? KeepSyncColors.mutedDark : KeepSyncColors.mutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KeepSyncColors.volt,
        linearTrackColor: KeepSyncColors.ink3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeepSyncColors.onVolt;
          }
          return isDark ? KeepSyncColors.mutedDark : KeepSyncColors.mutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KeepSyncColors.volt;
          }
          return isDark ? KeepSyncColors.ink3 : KeepSyncColors.borderLight;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? KeepSyncColors.volt : KeepSyncColors.ink,
        textColor: scheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? KeepSyncColors.ink2 : KeepSyncColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: KeepSyncColors.volt,
        unselectedLabelColor:
            isDark ? KeepSyncColors.mutedDark : KeepSyncColors.mutedLight,
        indicatorColor: KeepSyncColors.volt,
        dividerColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ).copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

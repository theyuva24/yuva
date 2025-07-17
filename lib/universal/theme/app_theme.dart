import 'package:flutter/material.dart';
import 'neon_theme.dart';

class AppTheme {
  // Neon dark theme color palette
  static const Color deepCharcoal = Color(0xFF0D0D0D); // App Background
  static const Color darkSurface = Color(0xFF1A1A1A); // Card/Input Background
  static const Color softGrayBorder = Color(0xFF2A2A2A); // Divider/Border
  static const Color neonCyan = Color(0xFF00FFFF); // Primary Accent
  static const Color limeGreen = Color(0xFF00FF85); // Secondary Accent
  static const Color magentaPink = Color(0xFFFF2CBE); // Highlight Accent
  static const Color violet = Color(0xFFB53FFF); // Optional Gradient End
  static const Color textPrimary = Color(0xFFF5F5F5); // Primary Text
  static const Color textSecondary = Color(0xFF9CA3AF); // Secondary Text
  static const Color placeholderText = Color(0xFF666666); // Placeholder Text
  static const Color inputFieldShadow = Color(0x8000FFFF); // Cyan with blur
  static const Color buttonElevation = Color(0x6600FF85); // Green glow

  // Gradients
  static const LinearGradient sendOtpGradient = LinearGradient(
    colors: [limeGreen, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient optionalGradient = LinearGradient(
    colors: [magentaPink, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepCharcoal,
    fontFamily: 'Inter',

    colorScheme: const ColorScheme.dark(
      background: deepCharcoal,
      surface: darkSurface,
      primary: neonCyan,
      secondary: limeGreen,
      error: magentaPink,
      onPrimary: Colors.black,
      onBackground: textPrimary,
      onSurface: textPrimary,
      outline: softGrayBorder,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: deepCharcoal,
      foregroundColor: neonCyan,
      elevation: 0,
      centerTitle: true,
    ),

    cardColor: darkSurface,
    dividerColor: softGrayBorder,

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: limeGreen,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        elevation: 8,
        shadowColor: buttonElevation,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      hintStyle: const TextStyle(color: placeholderText),
      prefixIconColor: neonCyan,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: softGrayBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: softGrayBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: neonCyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: magentaPink, width: 2),
      ),
    ),

    shadowColor: inputFieldShadow,

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: neonCyan,
        shadows: [Shadow(blurRadius: 12, color: neonCyan)],
      ),
      bodyMedium: TextStyle(fontSize: 16, color: textPrimary),
      labelSmall: TextStyle(fontSize: 12, color: textSecondary),
      bodySmall: TextStyle(
        fontSize: 14,
        color: placeholderText,
      ), // Placeholder text
    ),
  );

  static final ThemeData neonTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NeonColors.background,
    fontFamily: 'Orbitron',
    colorScheme: const ColorScheme.dark(
      background: NeonColors.background,
      surface: NeonColors.inputFill,
      primary: NeonColors.neonCyan,
      secondary: NeonColors.neonGreen,
      error: NeonColors.neonMagenta,
      onPrimary: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white,
      outline: NeonColors.neonCyan,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NeonColors.background,
      foregroundColor: NeonColors.neonCyan,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: NeonColors.inputFill,
    dividerColor: NeonColors.neonCyan,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NeonColors.neonGreen,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: NeonTextStyles.button,
        elevation: 8,
        shadowColor: NeonColors.neonGreen.withOpacity(0.4),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NeonColors.inputFill,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIconColor: NeonColors.neonCyan,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NeonColors.neonCyan),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NeonColors.neonCyan, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NeonColors.neonCyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NeonColors.neonMagenta, width: 2),
      ),
    ),
    shadowColor: NeonColors.neonCyan.withOpacity(0.2),
    textTheme: TextTheme(
      headlineLarge: NeonTextStyles.logo,
      bodyMedium: const TextStyle(fontSize: 16, color: Colors.white),
      labelSmall: const TextStyle(fontSize: 12, color: Colors.grey),
      bodySmall: const TextStyle(fontSize: 14, color: Colors.grey),
    ),
  );
  // To use the neon theme globally:
  // MaterialApp(theme: AppTheme.neonTheme, ...)
}

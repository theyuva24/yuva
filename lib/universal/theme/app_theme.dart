import 'package:flutter/material.dart';

class AppThemeLight {
  // Core Colors
  static const Color background = Color(0xFFF6F3FB); // Lavender background
  static const Color primary = Color(0xFFB39DDB); // Lavender (Purple 200)
  static const Color secondary = Color(
    0xFF9575CD,
  ); // Slightly deeper lavender (Purple 400)
  static const Color accent = Color(0xFF7E57C2); // Accent purple (Purple 600)
  static const Color surface = Color(0xFFFFFFFF); // White for cards/fields
  static const Color textDark = Color(0xFF2D1457); // Deep purple for text
  static const Color textLight = Color(
    0xFF7C6FAF,
  ); // Soft lavender for secondary text
  static const Color border = Color(0xFFE1D7F0); // Light lavender border

  // Gradient for Call-to-Action Buttons
  static const LinearGradient actionGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Urbanist',
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSurface: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        prefixIconColor: primary,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark, fontSize: 18),
        bodyMedium: TextStyle(color: textLight, fontSize: 16),
        labelLarge: TextStyle(color: primary, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(primary),
          foregroundColor: MaterialStateProperty.all(Colors.white),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      dividerColor: border,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const GradientButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppThemeLight.actionGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

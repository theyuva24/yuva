import 'package:flutter/material.dart';

class AppThemeLight {
  // Brand Primaries
  static const Color primary500 = Color(0xFFA68EFF); // Main brand purple
  static const Color primary600 = Color(0xFF7D5FFF); // Darker purple
  static const Color secondary500 = Color(0xFFFFCC4D); // Yellow accent
  static const Color blue = Color(0xFF0095F6); // Social/utility accent

  // Neutrals & Greyscale
  static const Color light1 = Color(0xFFFFFFFF); // Page background
  static const Color light2 = Color(0xFFF5F5F5); // Card & field background
  static const Color light3 = Color(0xFF888888); // Placeholder text
  static const Color light4 = Color(0xFFD1D1D1); // Secondary text
  static const Color dark1 = Color(0xFF000000); // Primary text
  static const Color dark2 = Color(0xFF222222); // Subtle dark text
  static const Color dark3 = Color(0xFF2E2E2E); // Divider
  static const Color dark4 = Color(0xFF3A3A3A); // Secondary divider

  // Status & Semantic
  static const Color red = Color(0xFFFF5A5A); // Error states
  static const Color offWhite = Color(0xFFF2F2F2); // Subtle background tint

  // Aliases
  static const Color primary = primary500;
  static const Color primaryLight = light2;
  static const Color primaryDark = primary600;
  static const Color secondary = secondary500;
  static const Color accent = blue;
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = secondary500;
  static const Color error = red;
  static const Color info = blue;
  static const Color background = light1;
  static const Color surface = light2;
  static const Color textPrimary = dark1;
  static const Color textSecondary = light4;
  static const Color divider = light2;
  static const Color transparent = Colors.transparent;
  static const Color white24 = Colors.white24;

  static const LinearGradient actionGradient = LinearGradient(
    colors: [primary500, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary500,
        secondary: secondary500,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        error: red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary500,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: light3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: primary600, width: 1.5),
        ),
        prefixIconColor: primary500,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: dark1, fontSize: 18),
        bodyMedium: TextStyle(color: light4, fontSize: 16),
        labelLarge: TextStyle(color: primary500, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(primary500),
          foregroundColor: MaterialStatePropertyAll(Colors.white),
          padding: MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      dividerColor: divider,
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

class AppThemeDark {
  // Brand Primaries
  static const Color primary500 = Color(0xFFA68EFF); // Main purple
  static const Color primary600 = Color(0xFF7D5FFF); // Darker purple
  static const Color secondary500 = Color(0xFFFFCC4D); // Yellow accent
  static const Color blue = Color(0xFF0095F6);

  // Neutrals & Greyscale
  static const Color light1 = Color(0xFFFFFFFF); // Text
  static const Color light2 = Color(0xFFEFEFEF); // Borders
  static const Color light3 = Color(0xFFD1D1D1); // Secondary text
  static const Color light4 = Color(0xFF888888); // Muted text
  static const Color dark1 = Color(0xFF000000); // Background
  static const Color dark2 = Color(0xFF0A0A0A); // Dark surface
  static const Color dark3 = Color(0xFF161017); // Cards
  static const Color dark4 = Color(0xFF1A111F); // Panels

  // Status & Semantic
  static const Color red = Color(0xFFFF5A5A);
  static const Color offWhite = Color(0xFFD0DFFF);

  // Aliases
  static const Color primary = primary500;
  static const Color primaryDark = primary600;
  static const Color secondary = secondary500;
  static const Color accent = blue;
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = secondary500;
  static const Color error = red;
  static const Color info = blue;
  static const Color background = dark2;
  static const Color surface = dark3;
  static const Color textPrimary = light1;
  static const Color textSecondary = light3;
  static const Color divider = dark4;
  static const Color transparent = Colors.transparent;
  static const Color white24 = Colors.white24;

  static const LinearGradient actionGradient = LinearGradient(
    colors: [primary500, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary500,
        secondary: secondary500,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        error: red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary500,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: light4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: primary600, width: 1.5),
        ),
        prefixIconColor: primary500,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: light1, fontSize: 18),
        bodyMedium: TextStyle(color: light4, fontSize: 16),
        labelLarge: TextStyle(color: primary500, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(primary500),
          foregroundColor: MaterialStatePropertyAll(Colors.white),
          padding: MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      dividerColor: divider,
    );
  }
}

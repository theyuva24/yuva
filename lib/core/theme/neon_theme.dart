import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonColors {
  static const background = Color(0xFF181C23);
  static const neonCyan = Color(0xFF00F6FF);
  static const neonGreen = Color(0xFF00FF85);
  static const neonBlue = Color(0xFF00B2FF);
  static const neonMagenta = Color(0xFFFF00E0);
  static const inputFill = Color(0xFF232733);
}

class NeonGradients {
  static const button = LinearGradient(
    colors: [NeonColors.neonGreen, NeonColors.neonCyan, NeonColors.neonBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class NeonTextStyles {
  static final logo = GoogleFonts.orbitron(
    textStyle: const TextStyle(
      fontSize: 56,
      fontWeight: FontWeight.bold,
      color: NeonColors.neonCyan,
      letterSpacing: 4,
      shadows: [
        Shadow(
          blurRadius: 32,
          color: NeonColors.neonCyan,
          offset: Offset(0, 0),
        ),
        Shadow(blurRadius: 8, color: NeonColors.neonCyan, offset: Offset(0, 0)),
      ],
    ),
  );
  static const subtitle = TextStyle(
    color: Colors.grey,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );
  static const button = TextStyle(
    fontSize: 20,
    color: Colors.black,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );
}

class NeonDecorations {
  static BoxDecoration input = BoxDecoration(
    color: NeonColors.inputFill,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: NeonColors.neonCyan.withOpacity(0.2), width: 1.5),
  );
}

class NeonBackground extends StatelessWidget {
  const NeonBackground({super.key, this.child});
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeonColors.background,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _NeonLinesPainter())),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _NeonLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintCyan =
        Paint()
          ..color = NeonColors.neonCyan.withOpacity(0.7)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final paintMagenta =
        Paint()
          ..color = NeonColors.neonMagenta.withOpacity(0.7)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    // Top left curve
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-40, -40), radius: 160),
      0.2,
      1.5,
      false,
      paintCyan,
    );
    // Bottom left curve
    canvas.drawArc(
      Rect.fromCircle(center: Offset(-60, size.height + 60), radius: 180),
      3.8,
      1.5,
      false,
      paintCyan,
    );
    // Top right magenta
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width + 40, 0), radius: 140),
      3.5,
      1.2,
      false,
      paintMagenta,
    );
    // Bottom right magenta
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width + 60, size.height + 60),
        radius: 180,
      ),
      3.8,
      1.5,
      false,
      paintMagenta,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

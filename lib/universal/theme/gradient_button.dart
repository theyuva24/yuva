import 'package:flutter/material.dart';
import 'app_theme.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final double borderRadius;
  final double elevation;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.gradient,
    this.borderRadius = 20,
    this.elevation = 8,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Gradient usedGradient = gradient ?? AppTheme.sendOtpGradient;
    return Material(
      color: Colors.transparent,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: usedGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.buttonElevation,
                blurRadius: 16,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: padding,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

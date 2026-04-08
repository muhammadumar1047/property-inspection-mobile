import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final double? buttonWidth;
  final double? buttonHeight;
  final Color buttonColor;
  final Color textColor;
  final String title;
  final Color borderColor;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isLoading;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.buttonColor,
    required this.title,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
    this.buttonWidth,
    this.buttonHeight,
    this.icon,
    this.isLoading = false,
    this.fontSize,
    this.fontWeight,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: buttonWidth ?? double.infinity,
        height: buttonHeight ?? height * 0.07,
        decoration: BoxDecoration(
          color: gradient == null ? buttonColor : null,
          gradient: gradient,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (gradient != null)
              BoxShadow(
                color: buttonColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSize ?? 16,
                        color: textColor,
                        fontWeight: fontWeight ?? FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: textColor, size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Navy Blue and White Theme
  static const Color primary = Color(0xFF2E5BFF); // Professional navy blue
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFF3B82F6);
  
    static const Color white = Colors.white;
  // Dark Theme Background Colors - Enhanced Navy
  static const Color background = Color(0xFF0F172A); // Deep navy background
  static const Color surface = Color(0xFF1E293B); // Lighter navy for surfaces
  static const Color cardBg = Color(0xFF1E293B); // Card background
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFF94A3B8); // Light blue-gray
  static const Color textHint = Color(0xFF64748B);
  
  // Status Colors - Navy Blue Theme
  static const Color success = Color(0xFF2E5BFF); // Navy blue for success
  static const Color warning = Color(0xFFF59E0B); // Amber for pending
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // UI Colors
  static const Color border = Color(0xFF334155); // Navy border
  static const Color cardBorder = Color(0xFF334155);
  static const Color cardBackground = Color(0xFF1E293B);
  static const Color divider = Color(0xFF334155);
  
  // Specific Status Colors
  static const Color pending = Color(0xFFF59E0B); // Amber
  static const Color done = Color(0xFF2E5BFF); // Navy blue
  static const Color complete = Color(0xFF2E5BFF);
  static const Color incomplete = Color(0xFFEF4444);
  
  // Gradient Colors - Navy Blue Variations
  static const Color gradient1 = Color(0xFF2E5BFF);
  static const Color gradient2 = Color(0xFF1E3A8A);
  static const Color gradient3 = Color(0xFF1E40AF);
  
  // Gradients - Navy Blue Theme
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradient1, gradient2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
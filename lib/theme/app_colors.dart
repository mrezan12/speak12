import 'package:flutter/material.dart';

/// Light brand palette aligned with Duolingo-like tokens (T04b / issue #27).
/// Keep UI mostly Snow + Polar + Eel; Feather Green is the signature.
abstract final class AppColors {
  /// Snow — main canvas
  static const Color background = Color(0xFFFFFFFF);

  /// Polar — cards / soft panels
  static const Color surface = Color(0xFFF7F7F7);

  /// Swan — subtle fills / stronger surface contrast
  static const Color surfaceVariant = Color(0xFFE5E5E5);

  /// Feather Green — brand CTA
  static const Color primary = Color(0xFF58CC02);

  /// Button green shadow / pressed
  static const Color primaryDark = Color(0xFF58A700);

  /// Bee — rare accent (XP / selected highlight)
  static const Color secondary = Color(0xFFFFC800);

  /// Same as Feather Green for positive states
  static const Color success = Color(0xFF58CC02);

  /// Cardinal — errors / wrong
  static const Color error = Color(0xFFFF4B4B);

  /// Fox — warnings / streak energy
  static const Color warning = Color(0xFFFF9600);

  /// Eel — primary text
  static const Color textPrimary = Color(0xFF4B4B4B);

  /// Wolf — secondary text
  static const Color textSecondary = Color(0xFF777777);

  /// Hare — hints / muted
  static const Color textHint = Color(0xFFAFAFAF);

  /// Swan — dividers / borders
  static const Color divider = Color(0xFFE5E5E5);
  static const Color cardBorder = Color(0xFFE5E5E5);
}

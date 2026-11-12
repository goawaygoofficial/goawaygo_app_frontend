import 'package:flutter/material.dart';

class ColorsUtil {
  static const transparent = Colors.transparent;

  static const primary = Color(0xFF004AAD);

  /// Decoration only (loaders, gradients): too light for white text on it.
  static const primaryLight = Color(0xFF7AAEEB);

  // The brand oranges: the logo, icons, tiles, gradients and decoration. Text uses the colours below.
  static const brandOrange = Color(0xFFF26C32);
  static const brandOrangeLight = Color(0xFFFF8F5E);
  static const brandOrangeLighter = Color.fromARGB(255, 255, 160, 119);
  static const brandOrangeDark = Color.fromARGB(255, 236, 84, 29);

  // ---- Colours for text, meeting WCAG 2.2 AA (4.5:1); the website uses the same (4.7) ----

  /// Orange text on white, and orange behind white text (4.55:1).
  static const secondary = Color(0xFFD0480D);

  /// Orange panels behind white text: the lighter half of a two-tone card.
  static const secondaryLight = secondary;

  /// The darker half of a two-tone card, and orange links on white (6.4:1).
  static const secondaryDark = Color(0xFFA83A0B);

  /// Orange text and icons on the blue background (4.8:1 or more).
  static const secondaryLighter = Color(0xFFFFD0BA);

  /// Fields and chips on the blue background, behind white text (4.6:1).
  static const field = Color(0xFF2074D7);

  /// Quieter white text on the blue background (6.3:1).
  static const textMuted = Color(0xD9FFFFFF);

  static const whiteColor = Colors.white;
  static const whiteLight = Color(0xFFF5F5F5);

  static var error = Colors.red.shade500;
  static var errorLight = Colors.red.shade50;

  static var success = Colors.green.shade500;

  static const LinearGradient orangeWhiteGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    // A soft peach at the end keeps blue and orange text on it readable.
    colors: [whiteColor, secondaryLighter],
  );
}

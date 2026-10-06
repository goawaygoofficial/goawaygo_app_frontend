import 'package:flutter/material.dart';

class ColorsUtil {
  static const transparent = Colors.transparent;

  static const primary = Color(0xFF004AAD);
  static const primaryLight = Color(0xFF7AAEEB);

  static const secondary = Color(0xFFF26C32);
  static const secondaryLight = Color(0xFFFF8F5E);
  static const secondaryLighter = Color.fromARGB(255, 255, 160, 119);
  static const secondaryDark = Color.fromARGB(255, 236, 84, 29);

  static const whiteColor = Colors.white;
  static const whiteLight = Color(0xFFF5F5F5);

  static var error = Colors.red.shade500;
  static var errorLight = Colors.red.shade50;

  static var success = Colors.green.shade500;

  static const LinearGradient orangeWhiteGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [whiteColor, secondaryLighter],
  );
}

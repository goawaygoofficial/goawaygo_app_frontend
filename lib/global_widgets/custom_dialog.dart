import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class CustomDialogs {
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) async {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: ColorsUtil.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.symmetric(
          vertical: 0.03 * height,
          horizontal: 0.04 * width,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: height * 0.1),
            Icon(
              Icons.check_circle_outline_rounded,
              color: ColorsUtil.success,
              size: height * 0.05,
            ),
            SizedBox(height: height * 0.02),
            Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: ColorsUtil.whiteColor,
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(duration);
    if (context.mounted) {
      Navigator.of(context).pop();
      if (onDismiss != null) onDismiss();
    }
  }

  static Future<void> showErrorDialog({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) async {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: ColorsUtil.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(
          vertical: 0.03 * height,
          horizontal: 0.04 * width,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: height * 0.1),
            Icon(
              Icons.error_outline_rounded,
              color: ColorsUtil.error,
              size: height * 0.05,
            ),
            SizedBox(height: height * 0.02),
            Text(
              message,
              style: TextStyle(
                color: ColorsUtil.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    await Future.delayed(duration);
    if (context.mounted) Navigator.of(context).pop();
    if (onDismiss != null) onDismiss();
  }
}

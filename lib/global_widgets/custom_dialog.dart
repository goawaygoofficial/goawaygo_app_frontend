import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class CustomDialogs {
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) async {
    await _showTimed(
      context: context,
      dismissible: false,
      duration: duration,
      dialog: _StatusDialog(
        // English sentences are translated here; already translated text stays as it is.
        message: tr(message),
        icon: Icons.check_circle_outline_rounded,
        iconColor: ColorsUtil.success,
      ),
    );
    if (onDismiss != null && context.mounted) onDismiss();
  }

  static Future<void> showErrorDialog({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) async {
    await _showTimed(
      context: context,
      dismissible: true,
      duration: duration,
      dialog: _StatusDialog(
        // English sentences are translated here; already translated text stays as it is.
        message: tr(message),
        icon: Icons.error_outline_rounded,
        iconColor: ColorsUtil.error,
      ),
    );
    if (onDismiss != null && context.mounted) onDismiss();
  }

  /// Asks the user to confirm an action. Never auto-dismisses. Returns `true` only if they chose
  /// [confirmLabel]; Cancel, the back button and tapping outside return `false`.
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _StatusDialog(
        // English sentences are translated here; already translated text stays as it is.
        message: tr(message),
        icon: Icons.help_outline_rounded,
        iconColor: ColorsUtil.whiteColor,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorsUtil.whiteColor,
              side: const BorderSide(color: ColorsUtil.whiteColor, width: 2),
              shape: const StadiumBorder(),
            ),
            child: Text(
              tr('Cancel'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsUtil.secondary,
              foregroundColor: ColorsUtil.whiteColor,
              shape: const StadiumBorder(),
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Shows [dialog] and closes it after [duration] unless the user already closed it. (Popping blindly after
  /// the delay would close whatever screen is underneath if the user had dismissed the dialog themselves.)
  static Future<void> _showTimed({
    required BuildContext context,
    required bool dismissible,
    required Duration duration,
    required Widget dialog,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    var open = true;
    final closed = showDialog<void>(
      context: context,
      barrierDismissible: dismissible,
      builder: (_) => dialog,
    ).whenComplete(() => open = false);
    await Future.any([closed, Future<void>.delayed(duration)]);
    if (open && navigator.mounted) navigator.pop();
    await closed;
  }
}

/// The app's dialog: primary-blue rounded box, logo, an icon and a bold message, plus optional actions.
class _StatusDialog extends StatelessWidget {
  const _StatusDialog({
    required this.message,
    required this.icon,
    required this.iconColor,
    this.actions,
  });

  final String message;
  final IconData icon;
  final Color iconColor;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    return AlertDialog(
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
          Icon(icon, color: iconColor, size: height * 0.05),
          SizedBox(height: height * 0.02),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: ColorsUtil.whiteColor,
            ),
          ),
          if (actions != null) ...[
            SizedBox(height: height * 0.025),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}

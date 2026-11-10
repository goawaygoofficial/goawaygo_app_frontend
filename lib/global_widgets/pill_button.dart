import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// The app's orange pill button (the website's `Button`): [quiet] is the outlined variant for secondary actions;
/// [large] is the big one for a screen's main action.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.quiet = false,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool quiet;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: quiet ? Colors.transparent : ColorsUtil.secondary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: quiet
          ? Colors.transparent
          : ColorsUtil.secondary.withValues(alpha: 0.5),
      disabledForegroundColor: Colors.white70,
      elevation: 0,
      side: quiet ? const BorderSide(color: Colors.white38) : null,
      shape: const StadiumBorder(),
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 36, vertical: 14)
          : const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    );
    final text = Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: large ? 17 : null,
      ),
    );
    return icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: text)
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: text,
          );
  }
}

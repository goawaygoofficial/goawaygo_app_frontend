import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// The round button between two fields that swaps them (places, or dates). A 48 x 48 tap target with a label
/// for screen readers (WCAG 2.5.8, 4.1.2).
class SwapButton extends StatelessWidget {
  const SwapButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, color: ColorsUtil.whiteColor),
      style: IconButton.styleFrom(
        backgroundColor: ColorsUtil.primary,
        side: BorderSide(color: ColorsUtil.whiteColor.withValues(alpha: 0.3)),
      ),
    );
  }
}

import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// What stops a booking search ("Choose a departure date."), shown above the Search button.
class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ColorsUtil.secondaryLighter,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class RentalsDatePickerUtils {
  static Future<void> selectDate(
    BuildContext context,
    TextEditingController controller,
    VoidCallback setStateCallback,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: ColorsUtil.secondaryLight,
              surface: ColorsUtil.primary,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: ColorsUtil.primaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setStateCallback();
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }
}

import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class TabOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TabOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.1,
          vertical: height * 0.01,
        ),
        margin: EdgeInsets.symmetric(horizontal: width * 0.015),
        decoration: BoxDecoration(
          color: selected ? ColorsUtil.secondary : ColorsUtil.transparent,
          borderRadius: BorderRadius.circular(width * 0.05),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? ColorsUtil.whiteColor : ColorsUtil.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

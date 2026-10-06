import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class ProfileButton extends StatefulWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const ProfileButton({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: ColorsUtil.secondaryLight,
              borderRadius: BorderRadius.circular(width * 0.04),
            ),
            child: Image.asset(
              widget.imagePath,
              height: height * 0.060,
              width: height * 0.060,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            widget.title,
            style: const TextStyle(
              color: ColorsUtil.whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

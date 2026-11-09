import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class ProfileButton extends StatefulWidget {
  final String title;
  final String imagePath;

  /// `null` for features that don't exist yet: the tile is dimmed and says "Coming soon", like the website.
  final VoidCallback? onTap;

  const ProfileButton({
    super.key,
    required this.title,
    required this.imagePath,
    this.onTap,
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

    final comingSoon = widget.onTap == null;

    final tile = Column(
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
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ColorsUtil.whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (comingSoon)
          Text(
            tr('COMING SOON'),
            style: TextStyle(
              color: ColorsUtil.whiteColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
      ],
    );

    if (comingSoon) {
      return Semantics(
        label: tr('{0}, coming soon', [widget.title]),
        excludeSemantics: true,
        child: Opacity(opacity: 0.55, child: tile),
      );
    }
    return GestureDetector(onTap: widget.onTap, child: tile);
  }
}

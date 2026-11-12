import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/material.dart';

class CustomNavItem extends StatelessWidget {
  final int currentPage;
  final Function(int) onTap;
  final UserModel? user;

  const CustomNavItem({
    super.key,
    required this.currentPage,
    required this.onTap,
    this.user,
  });

  Widget _navItem({
    required BuildContext context,
    required String iconPath,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = screenWidth * 0.075;
    const fontSize = 12.0;

    // The active tab's icon pops a little and an indicator grows under it (the website's tab bar).
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return GestureDetector(
      // The whole tab reacts, not only the icon and label: a tap in the gap between them was ignored (found by the
      // automated app tests, which tap the tab's centre).
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.15 : 1,
            duration: duration,
            curve: Curves.easeOutBack,
            child: Image.asset(
              iconPath,
              height: iconSize,
              color: isSelected ? ColorsUtil.secondary : ColorsUtil.primary,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isSelected ? ColorsUtil.secondary : ColorsUtil.primary,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: isSelected ? 24 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: ColorsUtil.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: ColorsUtil.whiteColor,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.08,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _navItem(
              context: context,
              iconPath: 'assets/icons/home.png',
              label: tr('HOME'),
              index: 0,
              isSelected: currentPage == 0,
            ),
            _navItem(
              context: context,
              iconPath: 'assets/icons/mytrips.png',
              label: tr('MY TRIPS'),
              index: 1,
              isSelected: currentPage == 1,
            ),
            _navItem(
              context: context,
              iconPath: 'assets/icons/wanderbook.png',
              label: 'WANDERBOOK',
              index: 2,
              isSelected: currentPage == 2,
            ),
            _navItem(
              context: context,
              iconPath: 'assets/icons/profile.png',
              label: user == null ? tr('SIGN IN') : 'PROFILE',
              index: 3,
              isSelected: currentPage == 3,
            ),
          ],
        ),
      ),
    );
  }
}

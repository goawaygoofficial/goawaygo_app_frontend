import 'package:flutter/material.dart';

import 'tab_option.dart';

import 'package:app_frontend/global_utils/colors.dart';

class WanderbookTabsHeader extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const WanderbookTabsHeader({
    super.key,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        alignment: Alignment.center,
        color: ColorsUtil.primary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TabOption(
              label: "My Wanderposts",
              selected: selectedTab == 0,
              onTap: () => onChanged(0),
            ),
            TabOption(
              label: "Feed Post",
              selected: selectedTab == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'wanderbook_profile_header.dart';
import 'wanderbook_tabs_header.dart';

class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;

  ProfileHeaderDelegate({required this.maxHeight, required this.minHeight});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return WanderbookProfileHeader(
      shrinkOffset: shrinkOffset,
      maxExtent: maxHeight,
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight;
  }
}

class TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int selectedTab;
  final ValueChanged<int> onChanged;
  final double height;

  TabsHeaderDelegate({
    required this.height,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: WanderbookTabsHeader(
        selectedTab: selectedTab,
        onChanged: onChanged,
      ),
    );
  }

  @override
  bool shouldRebuild(TabsHeaderDelegate oldDelegate) {
    return oldDelegate.selectedTab != selectedTab;
  }
}

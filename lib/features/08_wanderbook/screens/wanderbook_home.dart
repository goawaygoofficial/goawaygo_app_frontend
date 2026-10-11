// ignore_for_file: unused_local_variable

import 'dart:ui';

import 'package:app_frontend/features/08_wanderbook/data/mock_wanderbook.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/wanderbook_grid.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/wanderbook_search_bar.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/wanderbook_sliver_delegates.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:app_frontend/global_utils/colors.dart';

class WanderbookHome extends StatefulWidget {
  final UserModel? user;

  const WanderbookHome({super.key, this.user});

  @override
  State<WanderbookHome> createState() => _WanderbookHomeState();
}

class _WanderbookHomeState extends State<WanderbookHome> {
  final _searchController = TextEditingController();
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // The search bar filters the posts by destination, like the website.
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WanderPost> get _visiblePosts {
    final query = _searchController.text.trim().toLowerCase();
    final posts = selectedTab == 0 ? mockMyPosts : mockFeedPosts;
    return posts
        .where((post) => post.location.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: height * 0.015),
          child: CustomScrollView(
            slivers: [
              /// Fixed Search Bar
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: ColorsUtil.primary,
                toolbarHeight: height * 0.09,
                flexibleSpace: WanderbookSearchBar(
                  controller: _searchController,
                ),
                automaticallyImplyLeading: false,
              ),

              /// Animated Profile Header
              SliverPersistentHeader(
                delegate: ProfileHeaderDelegate(
                  maxHeight: height * 0.5,
                  minHeight: 0,
                ),
              ),

              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final maxHeaderHeight = height * 0.5;
                  final progress = (constraints.scrollOffset / maxHeaderHeight)
                      .clamp(0.0, 1.0);

                  // Spacer disappears as header collapses
                  final spacerHeight = lerpDouble(height * 0.01, 0, progress)!;

                  return SliverToBoxAdapter(
                    child: SizedBox(height: spacerHeight),
                  );
                },
              ),

              /// Sticky Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: TabsHeaderDelegate(
                  selectedTab: selectedTab,
                  onChanged: (v) => setState(() => selectedTab = v),
                  height: height * 0.06,
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: height * 0.015),
                  child: Text(
                    'Sample posts — Wanderbook isn’t connected to the backend yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              /// Posts
              WanderbookGrid(posts: _visiblePosts),
            ],
          ),
        ),
      ),
    );
  }
}

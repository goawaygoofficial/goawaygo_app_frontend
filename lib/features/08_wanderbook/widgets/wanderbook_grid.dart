import 'package:app_frontend/features/08_wanderbook/data/mock_wanderbook.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// The posts of the selected tab, one per row, like the website: a square gradient card with the place and
/// caption at the bottom. Shows a message when the search matches nothing.
class WanderbookGrid extends StatelessWidget {
  const WanderbookGrid({super.key, required this.posts});

  final List<WanderPost> posts;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: height * 0.04),
          child: Text(
            'No posts match that destination.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.025,
        vertical: height * 0.015,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, index) => _PostCard(post: posts[index]),
          childCount: posts.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: width * 0.025,
          mainAxisSpacing: height * 0.02,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final WanderPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorsUtil.secondaryLighter, ColorsUtil.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place, color: ColorsUtil.whiteColor, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  post.location.toUpperCase(),
                  style: const TextStyle(
                    color: ColorsUtil.whiteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            post.caption,
            style: const TextStyle(
              color: ColorsUtil.whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

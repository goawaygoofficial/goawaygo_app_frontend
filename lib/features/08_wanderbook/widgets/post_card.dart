import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/features/06_destinationInfo/screens/destination_info_screen.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/photo_carousel.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/report_sheet.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A post: who and where, its photos, likes, comments, caption, and a menu (report, or edit and delete yours).
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onChanged,
    required this.onDeleted,
    this.full = false,
  });

  final Post post;
  final ValueChanged<Post> onChanged;
  final VoidCallback onDeleted;

  /// On the post's own screen: the whole caption, and no comments button.
  final bool full;

  Future<void> _toggleLike(BuildContext context) async {
    if (context.read<UserProvider>().user == null) {
      showSignInHint(context);
      return;
    }
    final liked = !post.likedByYou;
    // Show it at once; the server's answer replaces it.
    onChanged(
      post.copyWith(likedByYou: liked, likes: post.likes + (liked ? 1 : -1)),
    );
    try {
      onChanged(await WanderbookService.like(post.publicId, liked));
    } on ApiException catch (error) {
      onChanged(post);
      if (context.mounted) showError(context, error);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Delete this post?')),
        content: Text(tr('Its photos are deleted too.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Delete')),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await WanderbookService.deletePost(post.publicId);
      onDeleted();
    } on ApiException catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

  void _openPlace(BuildContext context, PlaceTag place) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => DestinationInfoScreen(
          request: DestinationRequest.text(
            place.name,
            [place.name, place.country].where((p) => p.isNotEmpty).join(', '),
          ),
          onClose: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = post.place;
    final muted = TextStyle(color: Colors.white.withValues(alpha: 0.7));
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => openProfile(
                    context,
                    post.author.publicId,
                    preview: post.author,
                  ),
                  child: Row(
                    children: [
                      Avatar(url: post.author.photoUrl, size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (place != null)
                              Text(
                                place.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: muted,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: tr('More'),
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onSelected: (choice) {
                  switch (choice) {
                    case 'place':
                      _openPlace(context, place!);
                    case 'edit':
                      openPost(context, post.publicId, edit: true);
                    case 'delete':
                      _delete(context);
                    case 'report':
                      if (context.read<UserProvider>().user == null) {
                        showSignInHint(context);
                      } else {
                        showReportSheet(
                          context,
                          targetType: 'post',
                          target: post.publicId,
                          label: tr('this post'),
                        );
                      }
                  }
                },
                itemBuilder: (context) => [
                  if (place != null)
                    PopupMenuItem(
                      value: 'place',
                      child: Text(tr('About {0}', [place.name])),
                    ),
                  if (post.isYours) ...[
                    PopupMenuItem(value: 'edit', child: Text(tr('Edit'))),
                    PopupMenuItem(value: 'delete', child: Text(tr('Delete'))),
                  ] else
                    PopupMenuItem(value: 'report', child: Text(tr('Report'))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          PhotoCarousel(
            photos: post.photos,
            heroTag: postHeroTag(post.publicId),
          ),
          Row(
            children: [
              IconButton(
                tooltip: post.likedByYou ? tr('Unlike') : tr('Like'),
                icon: Icon(
                  post.likedByYou ? Icons.favorite : Icons.favorite_border,
                  color: post.likedByYou ? ColorsUtil.secondary : Colors.white,
                ),
                onPressed: () => _toggleLike(context),
              ),
              if (!full)
                IconButton(
                  tooltip: tr('Comments'),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      openPost(context, post.publicId, preview: post),
                ),
            ],
          ),
          Text(
            '${post.likes} ${post.likes == 1 ? 'like' : 'likes'}'
            '${!full && post.comments > 0 ? ' · ${post.comments} ${post.comments == 1 ? 'comment' : 'comments'}' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${post.author.name} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
                maxLines: full ? null : 3,
                overflow: full ? null : TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              timeAgo(post.createdAt) +
                  (post.editedAt != null ? ' · edited' : ''),
              style: muted.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// A profile's posts as square tiles of their first photo; opens the post.
class PostGrid extends StatelessWidget {
  const PostGrid({super.key, required this.posts, required this.empty});

  final List<Post> posts;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return StatusText(empty);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final cover = post.photos.isEmpty ? null : post.photos.first;
        return Semantics(
          button: true,
          label: post.place == null
              ? tr('Post')
              : tr('Post at {0}', [post.place!.name]),
          child: GestureDetector(
            onTap: () => openPost(context, post.publicId, preview: post),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.white.withValues(alpha: 0.08)),
                // The grid shows the centre; the post shows the whole original.
                if (cover != null)
                  Hero(
                    tag: postHeroTag(post.publicId),
                    child: Image.network(cover.url, fit: BoxFit.cover),
                  ),
                if (post.photos.length > 1)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

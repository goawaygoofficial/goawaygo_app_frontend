import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/paged_loader.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/post_card.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/profile_header.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/report_sheet.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Another traveller's profile: Follow (or request), their posts if you may see them, block and report.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.publicId});

  final String publicId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _posts = PagedLoader<Post>(
    (cursor) => WanderbookService.profilePosts(widget.publicId, cursor),
    () {
      if (mounted) setState(() {});
    },
  );
  Profile? _profile;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await WanderbookService.profile(widget.publicId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _error = null;
      });
      if (profile.canSeePosts) await _posts.reload();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  bool get _signedIn => context.read<UserProvider>().user != null;

  Future<void> _act(Future<void> Function() action) async {
    if (!_signedIn) {
      showSignInHint(context);
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } on ApiException catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleBlock(Profile profile) async {
    if (!profile.blockedByYou) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Block ${profile.name}?'),
          content: const Text("You won't see each other, and follows end."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block'),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }
    await _act(
      () => WanderbookService.block(widget.publicId, !profile.blockedByYou),
    );
  }

  String _followLabel(Profile profile) => switch (profile.relationship) {
    Relationship.following => 'Following',
    Relationship.requested => 'Requested',
    _ => profile.followsYou ? 'Follow back' : 'Follow',
  };

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      appBar: AppBar(
        backgroundColor: ColorsUtil.primary,
        foregroundColor: Colors.white,
        title: Text(profile?.name ?? ''),
        actions: [
          if (profile != null && profile.relationship != Relationship.self)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (choice) {
                if (choice == 'block') {
                  _toggleBlock(profile);
                } else if (!_signedIn) {
                  showSignInHint(context);
                } else {
                  showReportSheet(
                    context,
                    targetType: 'user',
                    target: widget.publicId,
                    label: profile.name,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(profile.blockedByYou ? 'Unblock' : 'Block'),
                ),
                const PopupMenuItem(value: 'report', child: Text('Report')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) StatusText(_error!),
            if (profile == null && _error == null) const StatusText('Loading…'),
            if (profile != null) ...[
              ProfileHeader(
                profile: profile,
                actions: [
                  if (!profile.blockedByYou &&
                      profile.relationship != Relationship.self)
                    PillButton(
                      label: _followLabel(profile),
                      quiet: profile.relationship != Relationship.none,
                      onPressed: _busy
                          ? null
                          : () => _act(
                              () => WanderbookService.follow(
                                widget.publicId,
                                profile.relationship == Relationship.none,
                              ),
                            ),
                    ),
                  if (profile.followsYou &&
                      profile.relationship != Relationship.none)
                    Text(
                      'Follows you',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (profile.blockedByYou)
                StatusText('You blocked ${profile.name}.')
              else if (!profile.canSeePosts)
                const StatusText(
                  'This profile is private. Follow to see their photos.',
                )
              else if (_posts.items == null)
                const StatusText('Loading…')
              else ...[
                PostGrid(posts: _posts.items!, empty: 'No posts yet.'),
                _posts.moreButton(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

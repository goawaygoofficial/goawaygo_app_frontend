import 'dart:async';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/features/08_wanderbook/screens/edit_profile_screen.dart';
import 'package:app_frontend/features/08_wanderbook/screens/new_post_screen.dart';
import 'package:app_frontend/features/08_wanderbook/screens/people_screen.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/paged_loader.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/post_card.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/profile_header.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Wanderbook tab (the website's `/wanderbook`). Signed in: your profile, "My Wanderposts" (your grid) and
/// "Feed" (everyone's newest posts). Signed out: the feed (anyone can view) and an invitation to sign in and post.
class WanderbookHome extends StatefulWidget {
  final UserModel? user;

  const WanderbookHome({super.key, this.user});

  @override
  State<WanderbookHome> createState() => _WanderbookHomeState();
}

class _WanderbookHomeState extends State<WanderbookHome> {
  late final _feed = PagedLoader<Post>(WanderbookService.feed, _refresh);
  late final _mine = PagedLoader<Post>(
    (cursor) => _me == null
        ? Future.value(const Paged<Post>([], null))
        : WanderbookService.profilePosts(_me!.publicId, cursor),
    _refresh,
  );
  final _search = TextEditingController();
  Timer? _searchTimer;
  List<Person>? _people;
  Profile? _me;
  int? _loadedFor;
  bool _requested = false;
  int? _requestedFor;
  bool _showFeed = false;

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Loads everything again for the signed-in user (or signed out).
  Future<void> _reload(int? userId) async {
    _loadedFor = userId;
    _me = null;
    final feed = _feed.reload();
    if (userId != null) {
      try {
        _me = await WanderbookService.myProfile();
      } on ApiException {
        // The feed still works; the header just doesn't show.
      }
      await _mine.reload();
    }
    await feed;
  }

  void _onSearch(String text) {
    _searchTimer?.cancel();
    final query = text.trim();
    if (query.length < 2) {
      setState(() => _people = null);
      return;
    }
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final people = await WanderbookService.searchPeople(query);
        if (mounted && _search.text.trim() == query) {
          setState(() => _people = people);
        }
      } on ApiException {
        if (mounted) setState(() => _people = const []);
      }
    });
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    // Something may have changed (a new post, an edited profile, ...).
    if (mounted) await _reload(_loadedFor);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    // Load on first show, and again when someone signs in or out.
    if (!_requested || _requestedFor != user?.id) {
      _requested = true;
      _requestedFor = user?.id;
      Future.microtask(() => _reload(user?.id));
    }
    final me = _me;
    final showFeed = user == null || _showFeed;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _reload(user?.id),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _search,
                maxLength: 50,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search travellers',
                  counterText: '',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ColorsUtil.secondary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_people != null)
                _people!.isEmpty
                    ? const StatusText('No travellers found.')
                    : Column(
                        children: [
                          for (final person in _people!)
                            PersonTile(person: person),
                        ],
                      ),
              const SizedBox(height: 12),
              if (user != null && me != null)
                ProfileHeader(
                  profile: me,
                  actions: [
                    PillButton(
                      label: 'New post',
                      icon: Icons.add_a_photo,
                      onPressed: () => _push(const NewPostScreen()),
                    ),
                    PillButton(
                      label: 'Edit profile',
                      quiet: true,
                      onPressed: () => _push(const EditProfileScreen()),
                    ),
                    if ((me.followRequests ?? 0) > 0)
                      PillButton(
                        label: 'Requests (${me.followRequests})',
                        quiet: true,
                        onPressed: () => _push(
                          const PeopleScreen(mode: PeopleMode.requests),
                        ),
                      ),
                  ],
                ),
              if (user == null) const _SignInInvite(),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('My Wanderposts'),
                      ),
                      ButtonSegment(value: true, label: Text('Feed')),
                    ],
                    selected: {showFeed},
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: ColorsUtil.secondary,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: Colors.white,
                    ),
                    onSelectionChanged: (value) =>
                        setState(() => _showFeed = value.first),
                  ),
                ),
              if (showFeed) ..._feedItems() else ..._mineItems(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _feedItems() {
    final items = _feed.items;
    if (_feed.error != null) return [StatusText(_feed.error!)];
    if (items == null) return [const StatusText('Loading…')];
    if (items.isEmpty) {
      return [const StatusText('No posts yet. Be the first to share a trip!')];
    }
    return [
      for (final post in items)
        PostCard(
          key: ValueKey(post.publicId),
          post: post,
          onChanged: (changed) => _feed.update(
            (all) => [
              for (final p in all) p.publicId == changed.publicId ? changed : p,
            ],
          ),
          onDeleted: () => _feed.update(
            (all) => all.where((p) => p.publicId != post.publicId).toList(),
          ),
        ),
      _feed.moreButton(),
    ];
  }

  List<Widget> _mineItems() {
    final items = _mine.items;
    if (_mine.error != null) return [StatusText(_mine.error!)];
    if (items == null) return [const StatusText('Loading…')];
    return [
      PostGrid(posts: items, empty: 'Share your first trip: tap New post.'),
      _mine.moreButton(),
    ];
  }
}

class _SignInInvite extends StatelessWidget {
  const _SignInInvite();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text(
            'Your travel scrapbook',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your trip photos as they are, tag the places, and follow other travellers. Sign in from the '
            'Profile tab to post.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

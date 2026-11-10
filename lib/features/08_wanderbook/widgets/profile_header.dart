import 'package:app_frontend/global_utils/decode_size.dart';
import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/features/08_wanderbook/screens/people_screen.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// Cover, profile photo, name, home town, counts and bio, with the actions under it (Follow, Edit profile, ...).
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.actions = const [],
    this.heroAvatar = false,
    this.placeholder = false,
  });

  final Profile profile;
  final List<Widget> actions;

  /// The photo is where a person's photo in a list flies to (not on your own tab, where it could appear twice).
  final bool heroAvatar;

  /// Only the cover, photo and name (drawn at once from a preview while the profile loads).
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final coverHeight = (width * 0.42).clamp(140.0, 240.0);
    return Column(
      children: [
        SizedBox(
          height: coverHeight + 48,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: coverHeight,
                  width: double.infinity,
                  child: profile.coverUrl == null
                      ? Image.asset(
                          'assets/images/home_image_01.png',
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          profile.coverUrl!,
                          cacheWidth: screenDecodeWidth(context),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: ColorsUtil.primary,
                    shape: BoxShape.circle,
                  ),
                  child: heroAvatar
                      ? Hero(
                          tag: avatarHeroTag(profile.publicId),
                          child: Avatar(url: profile.photoUrl, size: 90),
                        )
                      : Avatar(url: profile.photoUrl, size: 90),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                profile.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (profile.isPrivate)
              Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 18,
                  semanticLabel: tr('Private profile'),
                ),
              ),
          ],
        ),
        if (profile.homeTown.isNotEmpty)
          Text(
            profile.homeTown.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        if (!placeholder) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: tr('Posts'), count: profile.posts),
              _Stat(
                label: tr('Followers'),
                count: profile.followers,
                onTap: profile.canSeePosts
                    ? () => _openList(context, 'followers')
                    : null,
              ),
              _Stat(
                label: tr('Following'),
                count: profile.following,
                onTap: profile.canSeePosts
                    ? () => _openList(context, 'following')
                    : null,
              ),
            ],
          ),
          if (profile.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                profile.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ),
        ],
      ],
    );
  }

  void _openList(BuildContext context, String list) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PeopleScreen(
          mode: list == 'followers'
              ? PeopleMode.followers
              : PeopleMode.following,
          publicId: profile.publicId,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.count, this.onTap});

  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: ColorsUtil.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

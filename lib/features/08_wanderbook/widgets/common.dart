import 'package:app_frontend/global_utils/decode_size.dart';
import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/features/08_wanderbook/screens/post_screen.dart';
import 'package:app_frontend/features/08_wanderbook/screens/profile_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';

export 'package:app_frontend/global_widgets/pill_button.dart';
import 'package:flutter/material.dart';

/// Opens a traveller's profile on top of the current screen (Back returns). [preview]: the person as this screen
/// shows them, drawn at once (their photo flies into the profile header).
void openProfile(BuildContext context, String publicId, {Person? preview}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProfileScreen(publicId: publicId, preview: preview),
    ),
  );
}

/// Opens a post; [edit] opens it ready to change the caption and place. [preview]: the post as this screen shows
/// it, drawn at once (its first photo flies into place) until the fresh copy arrives.
void openPost(
  BuildContext context,
  String publicId, {
  bool edit = false,
  Post? preview,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PostScreen(publicId: publicId, startEditing: edit, preview: preview),
    ),
  );
}

/// Hero tags shared by a photo here and its copy on the next screen.
String postHeroTag(String publicId) => 'post-$publicId';

String avatarHeroTag(String publicId) => 'avatar-$publicId';

/// Shown when a signed-out user tries something that needs an account.
void showSignInHint(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr('Sign in from the Profile tab to do this.'))),
  );
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
}

/// A round profile photo, or a person icon when there is none.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.url, this.size = 44});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: ColorsUtil.secondary,
        child: url == null
            ? Icon(Icons.person, color: Colors.white, size: size * 0.6)
            : Image.network(
                url!,
                cacheWidth: decodeWidth(context, size),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    Icon(Icons.person, color: Colors.white, size: size * 0.6),
              ),
      ),
    );
  }
}

/// One person in a list: photo, name and home town (opening the profile), and optional buttons.
class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.person, this.trailing});

  final Person person;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Hero(
        tag: avatarHeroTag(person.publicId),
        child: Avatar(url: person.photoUrl),
      ),
      title: Text(
        person.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: person.homeTown.isEmpty
          ? null
          : Text(
              person.homeTown,
              style: TextStyle(color: ColorsUtil.textMuted),
            ),
      trailing: trailing,
      onTap: () => openProfile(context, person.publicId, preview: person),
    );
  }
}

/// Centered grey text for empty, loading and error states.
class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: ColorsUtil.textMuted),
      ),
    );
  }
}

import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/features/08_wanderbook/screens/post_screen.dart';
import 'package:app_frontend/features/08_wanderbook/screens/profile_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// Opens a traveller's profile on top of the current screen (Back returns).
void openProfile(BuildContext context, String publicId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ProfileScreen(publicId: publicId)),
  );
}

/// Opens a post; [edit] opens it ready to change the caption and place.
void openPost(BuildContext context, String publicId, {bool edit = false}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PostScreen(publicId: publicId, startEditing: edit),
    ),
  );
}

/// Shown when a signed-out user tries something that needs an account.
void showSignInHint(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Sign in from the Profile tab to do this.')),
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
      leading: Avatar(url: person.photoUrl),
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
      trailing: trailing,
      onTap: () => openProfile(context, person.publicId),
    );
  }
}

/// The app's orange pill button; [quiet] is the outlined variant.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.quiet = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: quiet ? Colors.transparent : ColorsUtil.secondary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: quiet
          ? Colors.transparent
          : ColorsUtil.secondary.withValues(alpha: 0.5),
      disabledForegroundColor: Colors.white70,
      elevation: 0,
      side: quiet ? const BorderSide(color: Colors.white38) : null,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    );
    final text = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    return icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: text)
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: text,
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
        style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
      ),
    );
  }
}

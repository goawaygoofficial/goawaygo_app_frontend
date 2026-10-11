import 'package:app_frontend/features/01_auth_register/screens/auth_screen.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The one sign-out flow (Profile header icon and the User Profile page): asks for confirmation, revokes the
/// session on the server, then replaces everything with the sign-in screen.
Future<void> confirmAndSignOut(BuildContext context) async {
  final confirmed = await CustomDialogs.showConfirmDialog(
    context: context,
    message: 'Sign out of Goaway?',
    confirmLabel: 'Sign out',
  );
  if (!confirmed || !context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  await context.read<UserProvider>().signOut();
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    (_) => false,
  );
}

/// Round header icon that signs out after a confirmation. Same size and colour as the header's notification bell.
class SignOutIconButton extends StatelessWidget {
  const SignOutIconButton({super.key, this.color, this.size});

  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      icon: Icon(Icons.logout_rounded, color: color, size: size),
      onPressed: () => confirmAndSignOut(context),
    );
  }
}

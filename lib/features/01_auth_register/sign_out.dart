import 'package:app_frontend/features/01_auth_register/screens/auth_screen.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The one sign-out flow (the User Profile page's Sign Out button): asks for confirmation, revokes the
/// session on the server, then replaces everything with the sign-in screen.
Future<void> confirmAndSignOut(BuildContext context) async {
  final confirmed = await CustomDialogs.showConfirmDialog(
    context: context,
    message: 'Sign out of GoAwayGo?',
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

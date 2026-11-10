import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Asks a signed-in user with an unverified email to open the link we emailed, with a way to get a new one.
///
/// The link opens the website, so the user is re-read when the app comes back to the foreground: after
/// verifying in the browser and returning, the banner disappears by itself.
class VerifyEmailBanner extends StatefulWidget {
  const VerifyEmailBanner({super.key});

  @override
  State<VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends State<VerifyEmailBanner>
    with WidgetsBindingObserver {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final provider = context.read<UserProvider>();
    if (provider.user?.emailVerified == false) provider.reloadUser();
  }

  Future<void> _resend() async {
    final provider = context.read<UserProvider>();
    final email = provider.user?.email;
    setState(() => _sending = true);
    try {
      await AuthService.resendVerificationEmail();
      if (!mounted) return;
      await CustomDialogs.showSuccessDialog(
        context: context,
        message: tr('We\'ve sent a new verification link to {0}.', [
          email ?? 'your email',
        ]),
      );
    } on ApiException catch (e) {
      // E.g. "already verified" (verified on the website meanwhile): refresh so the banner goes away.
      await provider.reloadUser();
      if (!mounted) return;
      await CustomDialogs.showErrorDialog(context: context, message: e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null || user.emailVerified) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: ColorsUtil.brandOrange, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: ColorsUtil.whiteColor,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: tr('Please verify your email\n'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: tr('Open the link we sent to {0}.', [user.email]),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: _sending ? null : _resend,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorsUtil.secondaryLighter,
                    ),
                  )
                : Text(
                    tr('Resend link'),
                    style: TextStyle(
                      color: ColorsUtil.secondaryLighter,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

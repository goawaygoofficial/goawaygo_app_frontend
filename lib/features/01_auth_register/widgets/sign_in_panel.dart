import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/features/01_auth_register/widgets/auth_button.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:app_frontend/global_widgets/legal_links.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Continue with Google" + "SIGN IN", cross-fading into the email form in place. The same panel is used on the
/// sign-in screen and on the Profile tab (and matches the website's).
///
/// On success the user is stored in [UserProvider], the welcome dialog is shown, then [onSignedIn] runs.
class SignInPanel extends StatefulWidget {
  const SignInPanel({
    super.key,
    required this.onSignedIn,
    required this.onRegister,
    required this.onForgotPassword,
  });

  final void Function(UserModel user) onSignedIn;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  @override
  State<SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<SignInPanel> {
  bool _showForm = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _welcome(UserModel user, String greeting) async {
    context.read<UserProvider>().signIn(user);
    await CustomDialogs.showSuccessDialog(
      context: context,
      message: '$greeting, ${user.name}!',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) widget.onSignedIn(user);
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final user = await AuthService.googleSignin();
      if (user == null || !mounted) return; // The user closed Google's dialog.
      Analytics.track(SignInCompleted(google: true));
      await _welcome(user, 'Welcome');
    } on ApiException catch (e) {
      if (!mounted) return;
      await CustomDialogs.showErrorDialog(context: context, message: e.message);
    }
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      await CustomDialogs.showErrorDialog(
        context: context,
        message: 'Please enter both email and password.',
      );
      return;
    }

    try {
      final user = await AuthService.signin(email, password);
      Analytics.track(SignInCompleted(google: false));
      if (!mounted) return;
      await _welcome(user, 'Welcome back');
    } on ApiException catch (e) {
      if (!mounted) return;
      await CustomDialogs.showErrorDialog(
        context: context,
        message: e.message,
        onDismiss: () {
          FocusManager.instance.primaryFocus?.unfocus();
          _emailController.clear();
          _passwordController.clear();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    InputDecoration fieldDecoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      contentPadding: EdgeInsets.symmetric(
        vertical: height * 0.02,
        horizontal: width * 0.05,
      ),
      fillColor: ColorsUtil.whiteColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 500),
      firstChild: Column(
        children: [
          AuthButton(
            icon: 'assets/icons/google_icon.png',
            text: 'Continue with Google',
            bgColor: ColorsUtil.whiteColor,
            textColor: ColorsUtil.secondary,
            onTap: _handleGoogleSignIn,
          ),
          SizedBox(height: height * 0.02),
          AuthButton(
            icon: 'assets/icons/email.png',
            text: 'SIGN IN',
            bgColor: ColorsUtil.secondary,
            textColor: ColorsUtil.whiteColor,
            onTap: () => setState(() => _showForm = true),
          ),
          SizedBox(height: height * 0.02),
          const SignUpNotice(),
          SizedBox(height: height * 0.01),
        ],
      ),
      secondChild: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Close sign-in form',
              icon: Icon(
                Icons.close_rounded,
                size: width * 0.075,
                color: ColorsUtil.whiteColor,
              ),
              onPressed: () => setState(() => _showForm = false),
            ),
          ),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: fieldDecoration('Enter your Email address...'),
          ),
          SizedBox(height: height * 0.02),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: fieldDecoration('Password...'),
          ),
          SizedBox(height: height * 0.01),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: ColorsUtil.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: height * 0.01),
          AuthButton(
            icon: 'assets/icons/email.png',
            text: 'SIGN IN',
            bgColor: ColorsUtil.secondary,
            textColor: ColorsUtil.whiteColor,
            onTap: _handleSignIn,
          ),
          SizedBox(height: height * 0.01),
          TextButton(
            onPressed: widget.onRegister,
            child: const Text(
              'Not Registered? Register',
              style: TextStyle(
                color: ColorsUtil.secondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      crossFadeState: _showForm
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
    );
  }
}

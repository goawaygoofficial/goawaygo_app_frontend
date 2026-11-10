// ignore_for_file: use_build_context_synchronously

import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/features/01_auth_register/widgets/auth_button.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:flutter/material.dart';

/// Requests a password-reset link. Only the email is collected here; the new password is chosen on the page the
/// emailed link opens, which proves the person owns the email.
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  /// Same wording whether or not the account exists, so this screen can't be used to find out who is registered.
  static const _resetRequestedMessage =
      'If an account exists for that email, we have sent a link to reset your password. Please check your inbox.';

  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      await CustomDialogs.showErrorDialog(
        context: context,
        message: tr('Please enter your email.'),
      );
      return;
    }

    try {
      await AuthService.requestPasswordReset(email);
      await CustomDialogs.showSuccessDialog(
        context: context,
        message: tr(_resetRequestedMessage),
        onDismiss: () {
          _emailController.clear();
          widget.onBack();
        },
      );
    } on ApiException catch (e) {
      await CustomDialogs.showErrorDialog(context: context, message: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.02,
            ),
            child: Column(
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: height * 0.15,
                  ),
                ),
                Text(
                  tr('Forgot Password?'),
                  style: TextStyle(
                    fontSize: 24,
                    color: ColorsUtil.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: height * 0.03),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    hintText: tr('Enter your registered email...'),
                    filled: true,
                    fillColor: ColorsUtil.whiteColor,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: height * 0.02,
                      horizontal: width * 0.05,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.03),
                AuthButton(
                  icon: 'assets/icons/lock.png',
                  text: tr('SEND RESET LINK'),
                  bgColor: ColorsUtil.secondary,
                  textColor: ColorsUtil.whiteColor,
                  onTap: _handleResetPassword,
                ),
                TextButton(
                  onPressed: widget.onBack,
                  child: Text(
                    tr('Back to Sign In'),
                    style: TextStyle(
                      color: ColorsUtil.secondaryLighter,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

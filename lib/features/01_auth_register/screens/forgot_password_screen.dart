// ignore_for_file: use_build_context_synchronously

import 'package:app_frontend/features/01_auth_register/screens/auth_screen.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/features/01_auth_register/widgets/auth_button.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (email.isEmpty || newPassword.isEmpty) {
      await CustomDialogs.showErrorDialog(
        context: context,
        message: 'Please fill all fields.',
      );
      return;
    }

    final error = await AuthService.forgotPassword(email, newPassword);

    if (error == null) {
      await CustomDialogs.showSuccessDialog(
        context: context,
        message: 'Verification email sent! Please check your inbox.',
        onDismiss: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 750),
              pageBuilder: (_, __, ___) => const AuthScreen(),
              transitionsBuilder: (_, animation, __, child) {
                final slide =
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    );
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                );

                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: fade, child: child),
                );
              },
            ),
          );
        },
      );
    } else {
      await CustomDialogs.showErrorDialog(context: context, message: error);
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
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 24,
                    color: ColorsUtil.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: height * 0.03),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Enter your registered email...",
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
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "New Password...",
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
                  ),
                ),
                SizedBox(height: height * 0.03),
                AuthButton(
                  icon: 'assets/icons/lock.png',
                  text: 'RESET PASSWORD',
                  bgColor: ColorsUtil.secondary,
                  textColor: ColorsUtil.whiteColor,
                  onTap: _handleResetPassword,
                ),
                TextButton(
                  onPressed: widget.onBack,
                  child: const Text(
                    "Back to Sign In",
                    style: TextStyle(
                      color: ColorsUtil.secondary,
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

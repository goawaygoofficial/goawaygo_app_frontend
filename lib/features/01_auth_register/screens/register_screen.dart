// ignore_for_file: use_build_context_synchronously

import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/features/01_auth_register/widgets/auth_button.dart';
import 'package:app_frontend/features/01_auth_register/widgets/feature_item.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:app_frontend/global_widgets/legal_links.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onBack;

  const RegisterScreen({super.key, required this.onBack});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isStrongPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,72}$',
    ); // 72: backend/BCrypt limit
    return regex.hasMatch(password);
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      await CustomDialogs.showErrorDialog(
        context: context,
        message: tr('Please fill all fields.'),
      );
      return;
    }

    if (!isStrongPassword(password)) {
      await CustomDialogs.showErrorDialog(
        context: context,
        message: tr(
          tr(
            'Password must be 8 to 72 characters long and include uppercase, lowercase, number, and special character.',
          ),
        ),
      );
      return;
    }

    try {
      await AuthService.signup(name, email, password);
      Analytics.track(SignUpCompleted());
      await CustomDialogs.showSuccessDialog(
        context: context,
        message: tr('Account created! You can now sign in.'),
        onDismiss: widget.onBack,
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
              horizontal: width * 0.04,
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

                /// --- Feature Items ---
                Column(
                  children: [
                    FeatureItem(
                      icon: 'assets/images/auth_image_01.png',
                      text: tr('Travel the World in Your Terms'),
                    ),
                    FeatureItem(
                      icon: 'assets/images/auth_image_02.png',
                      text: tr('Personalised Travel Plans'),
                    ),
                    FeatureItem(
                      icon: 'assets/images/auth_image_03.png',
                      text: tr('Your Own WanderBook'),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: tr('Enter your Name...'),
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
                SizedBox(height: height * 0.02),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: tr('Enter your Email address...'),
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
                SizedBox(height: height * 0.02),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: tr('Password...'),
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

                SizedBox(height: height * 0.02),
                const SignUpNotice(),
                SizedBox(height: height * 0.02),

                AuthButton(
                  icon: 'assets/icons/email.png',
                  text: tr('REGISTER'),
                  bgColor: ColorsUtil.secondary,
                  textColor: ColorsUtil.whiteColor,
                  onTap: _handleRegister,
                ),

                /// --- Back to Sign In ---
                TextButton(
                  onPressed: widget.onBack,
                  child: Text(
                    tr('Already have an account? Sign In'),
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

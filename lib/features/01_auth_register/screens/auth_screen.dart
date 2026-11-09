import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/features/01_auth_register/screens/forgot_password_screen.dart';
import 'package:app_frontend/features/01_auth_register/screens/register_screen.dart';
import 'package:app_frontend/features/01_auth_register/widgets/feature_item.dart';
import 'package:app_frontend/features/01_auth_register/widgets/sign_in_panel.dart';
import 'package:app_frontend/global_utils/bottom_bar/bottom_bar.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/legal_links.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/material.dart';

/// The sign-in screen: logo + SKIP, the feature list and the [SignInPanel]. After signing in it opens the app.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool showRegister = false;
  bool showForgotPassword = false;

  /// Replaces this screen with the app (bottom bar), sliding in from the right.
  void _openApp({UserModel? user, bool replace = true}) {
    final route = PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 750),
      pageBuilder: (_, _, _) => BottomBar(user: user),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
    final navigator = Navigator.of(context);
    replace ? navigator.pushReplacement(route) : navigator.push(route);
  }

  void _closeOverlays() {
    setState(() {
      showRegister = false;
      showForgotPassword = false;
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.02,
          ),
          child: Stack(
            children: [
              SizedBox.expand(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// --- Logo and Skip Row ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: width * 0.4,
                            height: height * 0.2,
                          ),
                          TextButton(
                            onPressed: () => _openApp(replace: false),
                            child: Text(
                              tr('SKIP'),
                              style: TextStyle(
                                color: ColorsUtil.whiteColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      /// --- Feature Items ---
                      const FeatureList(),

                      SizedBox(height: height * 0.01),
                      SignInPanel(
                        onSignedIn: (user) => _openApp(user: user),
                        onRegister: () => setState(() => showRegister = true),
                        onForgotPassword: () =>
                            setState(() => showForgotPassword = true),
                      ),
                      const LegalFooter(),
                    ],
                  ),
                ),
              ),
              SlideFadeTransition(
                visible: showRegister,
                onClose: _closeOverlays,
                child: RegisterScreen(onBack: _closeOverlays),
              ),
              SlideFadeTransition(
                visible: showForgotPassword,
                onClose: _closeOverlays,
                child: ForgotPasswordScreen(onBack: _closeOverlays),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: unused_field, use_build_context_synchronously

import 'package:app_frontend/features/01_auth_register/screens/forgot_password_screen.dart';
import 'package:app_frontend/features/01_auth_register/screens/register_screen.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/features/01_auth_register/widgets/auth_button.dart';
import 'package:app_frontend/features/01_auth_register/widgets/feature_item.dart';
import 'package:app_frontend/global_utils/bottom_bar/bottom_bar.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const AuthScreen({super.key, this.onClose});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _showForm = false;
  bool showRegister = false;
  bool showForgotPassword = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _controller;
  late Animation<Offset> _logoOffset;
  late Animation<Offset> _featureOffset;
  late Animation<double> _formOpacity;

  UserModel? _loggedInUser;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _logoOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.8),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _featureOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.6),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _formOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSignInTap() {
    setState(() {
      _showForm = true;
    });
    _controller.forward();
  }

  void _onBackTap() {
    _controller.reverse().then((_) {
      setState(() {
        _showForm = false;
      });
    });
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw Exception("Google ID token is null");

      final result = await AuthService.googleSignin(idToken);
      final user = result['user'];

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUser(user);

      await CustomDialogs.showSuccessDialog(
        context: context,
        message: 'Welcome, ${user.name}!',
        onDismiss: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 750),
              pageBuilder: (_, __, ___) => BottomBar(user: user),
              transitionsBuilder: (_, animation, __, child) {
                final slide = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
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
    } catch (e) {
      await CustomDialogs.showErrorDialog(
        context: context,
        message: e.toString().replaceAll("Exception: ", ""),
      );
    }
  }

  void _handleSignIn() async {
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
      final result = await AuthService.signin(email, password);
      final user = result['user'];

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUser(user);

      await CustomDialogs.showSuccessDialog(
        context: context,
        message: 'Welcome back, ${user.name}!',
        onDismiss: () {
          FocusManager.instance.primaryFocus?.unfocus();

          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 750),
              pageBuilder: (_, __, ___) => BottomBar(user: user),
              transitionsBuilder: (_, animation, __, child) {
                final slide = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
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
    } catch (e) {
      await CustomDialogs.showErrorDialog(
        context: context,
        message: e.toString().replaceAll('Exception: ', ''),
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
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return SizedBox.expand(
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
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        milliseconds: 750,
                                      ),
                                      pageBuilder:
                                          (_, __, ___) => const BottomBar(),
                                      transitionsBuilder: (
                                        _,
                                        animation,
                                        __,
                                        child,
                                      ) {
                                        final offsetAnimation = Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOut,
                                          ),
                                        );
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: const Text(
                                  "SKIP",
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
                          Column(
                            children: const [
                              FeatureItem(
                                icon: 'assets/images/auth_image_01.png',
                                text: 'Travel the World in Your Terms',
                              ),
                              FeatureItem(
                                icon: 'assets/images/auth_image_02.png',
                                text: 'Personalised Travel Plans',
                              ),
                              FeatureItem(
                                icon: 'assets/images/auth_image_03.png',
                                text: 'Your Own WanderBook',
                              ),
                            ],
                          ),

                          SizedBox(height: height * 0.01),
                          AnimatedCrossFade(
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
                                  onTap: _onSignInTap,
                                ),
                                SizedBox(height: height * 0.02),
                              ],
                            ),
                            secondChild: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: width * 0.075,
                                      color: ColorsUtil.whiteColor,
                                    ),
                                    onPressed: _onBackTap,
                                  ),
                                ),
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: "Enter your Email address...",
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
                                    hintText: "Password...",
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
                                SizedBox(height: height * 0.01),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        () => setState(
                                          () => showForgotPassword = true,
                                        ),
                                    child: const Text(
                                      "Forgot Password?",
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

                                /// --- Not Registered? Register ---
                                TextButton(
                                  onPressed:
                                      () => setState(() => showRegister = true),
                                  child: const Text(
                                    "Not Registered? Register",
                                    style: TextStyle(
                                      color: ColorsUtil.secondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            crossFadeState:
                                _showForm
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SlideFadeTransition(
                visible: showRegister,
                onClose: () {
                  setState(() {
                    showRegister = false;
                    FocusManager.instance.primaryFocus?.unfocus();
                  });
                },
                child: RegisterScreen(
                  onBack: () {
                    setState(() {
                      showRegister = false;
                      FocusManager.instance.primaryFocus?.unfocus();
                    });
                  },
                ),
              ),
              SlideFadeTransition(
                visible: showForgotPassword,
                onClose: () {
                  setState(() {
                    showForgotPassword = false;
                    FocusManager.instance.primaryFocus?.unfocus();
                  });
                },
                child: ForgotPasswordScreen(
                  onBack: () {
                    setState(() {
                      showForgotPassword = false;
                      FocusManager.instance.primaryFocus?.unfocus();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

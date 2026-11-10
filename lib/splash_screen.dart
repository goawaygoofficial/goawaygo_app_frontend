// ignore_for_file: unused_field, use_build_context_synchronously

import 'dart:async';

import 'package:app_frontend/features/01_auth_register/screens/auth_screen.dart';
import 'package:app_frontend/global_utils/bottom_bar/bottom_bar.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/animated_wave_background.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  bool _shrink = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoController.forward();

    // After scale up, reverse to shrink
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
        );
        _logoController.reset();
        _logoController.forward();
        _shrink = true;
      });
    });

    // Then navigate to auth with transition
    navigateToNextScreen();
  }

  Future<void> navigateToNextScreen() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // The animation, and the session being restored at the same time (main.dart).
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 3000)),
      userProvider.restored,
    ]);
    if (!mounted) return;

    if (userProvider.user != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (_, _, _) => BottomBar(user: userProvider.user),
          transitionsBuilder: (_, animation, _, child) {
            final slide = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation);
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(animation);

            return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: fade, child: child),
            );
          },
        ),
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: Stack(
        children: [
          const AnimatedWaveBackground(),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                height: height * 0.75,
                width: width * 0.75,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

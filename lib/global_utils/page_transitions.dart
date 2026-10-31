import 'package:flutter/material.dart';

/// How pages pushed on top of others come and go (the website's `usePageMotion`, "forward" and "back"): the new
/// page slides in a little from the right and fades in, while the page under it drifts a little to the left. Back
/// plays it in reverse. Nothing moves when the system asks for less motion.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  static final _enter = Tween<Offset>(
    begin: const Offset(0.12, 0),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  static final _under = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.06, 0),
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return SlideTransition(
      position: secondaryAnimation.drive(_under),
      child: SlideTransition(
        position: animation.drive(_enter),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }
}

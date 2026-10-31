import 'package:app_frontend/features/02_home/screens/home_screen.dart';
import 'package:app_frontend/features/07_trips/screens/my_trips_screen.dart';
import 'package:app_frontend/features/08_wanderbook/screens/wanderbook_home.dart';
import 'package:app_frontend/features/09_profile/screens/my_profile.dart';
import 'package:app_frontend/global_utils/bottom_bar/custom_nav_item.dart';
import 'package:app_frontend/global_widgets/analytics_consent_sheet.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  final UserModel? user;
  const BottomBar({super.key, this.user});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> with TickerProviderStateMixin {
  int _page = 0;

  /// 1 when the tab opened is to the right of the previous one, -1 to the left: the new tab glides in from there.
  int _direction = 1;
  bool _showBottomBar = true;

  late AnimationController _animationController;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    _pages.addAll([
      HomeScreen(
        user: widget.user,
        toggleBottomBar: _toggleBottomBar,
        onOpenProfile: () => _updatePage(3),
      ),
      MyTripsScreen(
        onPlanTrip: () => _updatePage(0),
        onSignIn: () => _updatePage(3),
        toggleBottomBar: _toggleBottomBar,
      ),
      WanderbookHome(user: widget.user),
      MyProfile(
        toggleBottomBar: _toggleBottomBar,
        onOpenTrips: () => _updatePage(1),
      ),
    ]);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (_showBottomBar) {
      _animationController.forward();
    }
    // Ask about usage statistics once the app is open (only builds with analytics, only until answered).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) askForAnalyticsConsentIfNeeded(context);
    });
  }

  void _updatePage(int index) {
    if (index == _page) return;
    setState(() {
      _direction = index > _page ? 1 : -1;
      _page = index;
    });
  }

  void _toggleBottomBar(bool show) {
    if (show) {
      setState(() => _showBottomBar = true);
      _animationController.forward();
    } else {
      _animationController.reverse().then((_) {
        setState(() => _showBottomBar = false);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Android Back: an open panel closes itself first (see [SlideFadeTransition]); otherwise another tab goes back
  /// to Home, and Back on Home leaves the app.
  void _onBack(bool didPop, Object? result) {
    if (didPop || SlideFadeTransition.anyOpen || _page == 0) return;
    _updatePage(0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: _onBack,
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      // Switching tabs: the new tab glides in from the side of the tab you came from (the website's tab motion).
      body: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(_page);
          return FadeTransition(
            opacity: animation,
            child: incoming
                ? SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0.08 * _direction, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  )
                : child,
          );
        },
        child: KeyedSubtree(key: ValueKey(_page), child: _pages[_page]),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeInOut,
                ),
              );

          final sizeAnimation = CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          );

          return SizeTransition(
            sizeFactor: sizeAnimation,
            alignment: AlignmentDirectional.topStart,
            child: SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: _animationController,
                child: CustomNavItem(
                  currentPage: _page,
                  onTap: _updatePage,
                  user: widget.user,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

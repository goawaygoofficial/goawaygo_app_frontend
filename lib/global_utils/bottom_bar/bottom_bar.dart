import 'package:app_frontend/features/02_home/screens/home_screen.dart';
import 'package:app_frontend/features/08_wanderbook/screens/wanderbook_home.dart';
import 'package:app_frontend/features/09_profile/screens/my_profile.dart';
import 'package:app_frontend/global_utils/bottom_bar/custom_nav_item.dart';
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
  bool _showBottomBar = true;

  late AnimationController _animationController;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    _pages.addAll([
      HomeScreen(user: widget.user, toggleBottomBar: _toggleBottomBar),
      const Center(child: Text('My Trips Page')),
      WanderbookHome(user: widget.user),
      MyProfile(user: widget.user, toggleBottomBar: _toggleBottomBar),
    ]);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (_showBottomBar) {
      _animationController.forward();
    }
  }

  void _updatePage(int index) {
    setState(() => _page = index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_page],
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

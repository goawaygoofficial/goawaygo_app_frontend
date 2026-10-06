import 'package:flutter/material.dart';

class SlideFadeTransition extends StatefulWidget {
  final Widget child;
  final bool visible;
  final VoidCallback? onClose;

  const SlideFadeTransition({
    super.key,
    required this.child,
    required this.visible,
    this.onClose,
  });

  @override
  State<SlideFadeTransition> createState() => _SlideFadeTransitionState();
}

class _SlideFadeTransitionState extends State<SlideFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isDisplayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.visible) {
      _isDisplayed = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SlideFadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible && !_isDisplayed) {
      setState(() => _isDisplayed = true);
      _controller.forward();
    } else if (!widget.visible && _isDisplayed) {
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() => _isDisplayed = false);
          widget.onClose!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDisplayed) return const SizedBox.shrink();

    return SlideTransition(position: _slideAnimation, child: widget.child);
  }
}

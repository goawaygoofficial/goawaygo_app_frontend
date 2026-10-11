import 'package:flutter/material.dart';

/// A full-screen panel that slides in from the right over the current screen (sign-in, search screens,
/// User Profile, ...). These panels are not routes, so the system Back button (Android back gesture) would close
/// the whole app; instead, Back closes the top-most open panel by calling [onClose].
class SlideFadeTransition extends StatefulWidget {
  final Widget child;
  final bool visible;

  /// Closes the panel: called by the system Back button, and after the closing animation finishes.
  final VoidCallback? onClose;

  const SlideFadeTransition({
    super.key,
    required this.child,
    required this.visible,
    this.onClose,
  });

  /// Whether any panel is open, so other Back handlers (the bottom bar) can leave Back to the panel.
  static bool get anyOpen => _SlideFadeTransitionState._open.isNotEmpty;

  @override
  State<SlideFadeTransition> createState() => _SlideFadeTransitionState();
}

class _SlideFadeTransitionState extends State<SlideFadeTransition>
    with SingleTickerProviderStateMixin {
  /// Open panels, most recently opened last. Panels can be nested (sign-in → Register), and Flutter tells every
  /// Back handler on the screen about a Back press, so only the last one here reacts to it.
  static final List<_SlideFadeTransitionState> _open = [];

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
      _open.add(this);
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SlideFadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible && !_isDisplayed) {
      setState(() => _isDisplayed = true);
      _open.add(this);
      _controller.forward();
    } else if (!widget.visible && _isDisplayed) {
      _open.remove(this);
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() => _isDisplayed = false);
          widget.onClose?.call();
        }
      });
    }
  }

  void _onBack(bool didPop, Object? result) {
    if (didPop || _open.isEmpty || _open.last != this) return;
    widget.onClose?.call();
  }

  @override
  void dispose() {
    _open.remove(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDisplayed) return const SizedBox.shrink();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

import 'package:flutter/material.dart';

/// Horizontally swiping, endless carousel: the centred card is full size; neighbours shrink and fade with
/// distance (the website's `TripIdeaCarousel`).
class StackedCardCarousel extends StatefulWidget {
  const StackedCardCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double height;

  @override
  State<StackedCardCarousel> createState() => _StackedCardCarouselState();
}

class _StackedCardCarouselState extends State<StackedCardCarousel> {
  // Use a high initialPage to simulate infinite scrolling
  final PageController _pageController = PageController(
    viewportFraction: 0.6,
    initialPage: 1000,
  );

  double currentPageValue = 1000.0;

  @override
  void initState() {
    super.initState();

    // Set initial page value
    _pageController.addListener(() {
      setState(() {
        currentPageValue = _pageController.page!;
      });
    });

    // Trigger rebuild after first frame to apply scaling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentPageValue = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final scale = (1 - ((currentPageValue - index).abs() * 0.3)).clamp(
            0.0,
            1.0,
          );
          return Transform.scale(
            scale: Curves.easeOut.transform(scale),
            child: Opacity(
              opacity: scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                child: widget.itemBuilder(context, index % widget.itemCount),
              ),
            ),
          );
        },
      ),
    );
  }
}

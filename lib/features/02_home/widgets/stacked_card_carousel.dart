import 'package:flutter/material.dart';

class StackedCardCarousel extends StatefulWidget {
  const StackedCardCarousel({super.key});

  @override
  State<StackedCardCarousel> createState() => _StackedCardCarouselState();
}

class _StackedCardCarouselState extends State<StackedCardCarousel> {
  // Use a high initialPage to simulate infinite scrolling
  final PageController _pageController = PageController(
    viewportFraction: 0.6,
    initialPage: 1000,
  );

  final List<Color> colors = [
    Colors.orange,
    Colors.deepOrange,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.deepOrangeAccent,
  ];

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
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: height * 0.28,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final actualIndex = index % colors.length;

          double scale = (1 - ((currentPageValue - index).abs() * 0.3)).clamp(
            0.0,
            1.0,
          );
          double opacity = scale;

          return Transform.scale(
            scale: Curves.easeOut.transform(scale),
            child: Opacity(
              opacity: opacity,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: width * 0.02),
                decoration: BoxDecoration(
                  color: colors[actualIndex],
                  borderRadius: BorderRadius.circular(width * 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Card ${actualIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

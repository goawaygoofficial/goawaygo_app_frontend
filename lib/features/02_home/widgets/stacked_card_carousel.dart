import 'package:app_frontend/features/02_home/data/trip_ideas.dart';
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

  final List<TripIdea> ideas = placeholderTripIdeas;

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
          final idea = ideas[index % ideas.length];

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
                padding: EdgeInsets.all(width * 0.05),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: idea.colors,
                  ),
                  borderRadius: BorderRadius.circular(width * 0.08),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                // Bottom-left text, as on the website: place, title, tagline.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${idea.destination}, ${idea.country}'.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

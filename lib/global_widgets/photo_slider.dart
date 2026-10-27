import 'dart:async';

import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PhotoSlide {
  const PhotoSlide({
    required this.title,
    this.subtitle,
    this.photo,
    this.onTap,
  });

  final String title;
  final String? subtitle;

  /// Null: a brand gradient instead.
  final Photo? photo;
  final VoidCallback? onTap;
}

/// Swipeable photo banner (the website's `PhotoSlider`): the place name on each photo and its credit
/// (photographer and licence, which Wikimedia and Unsplash require) in the corner, opening the source when tapped.
/// Moves on every 5 seconds until the user swipes; never on its own when the system asks for less motion.
class PhotoSlider extends StatefulWidget {
  const PhotoSlider({super.key, required this.slides, required this.height});

  final List<PhotoSlide> slides;
  final double height;

  @override
  State<PhotoSlider> createState() => _PhotoSliderState();
}

class _PhotoSliderState extends State<PhotoSlider> {
  static const _autoAdvance = Duration(seconds: 5);

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  bool _userMoved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTimer();
  }

  @override
  void didUpdateWidget(PhotoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides.length != widget.slides.length) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_userMoved || reducedMotion || widget.slides.length < 2) return;
    _timer = Timer.periodic(_autoAdvance, (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: widget.height,
            child: NotificationListener<ScrollStartNotification>(
              // A swipe by the user stops the automatic sliding.
              onNotification: (notification) {
                if (notification.dragDetails != null && !_userMoved) {
                  _userMoved = true;
                  _timer?.cancel();
                }
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => _Slide(slide: slides[index]),
              ),
            ),
          ),
        ),
        if (slides.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 16 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? ColorsUtil.whiteColor
                          : ColorsUtil.whiteColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final PhotoSlide slide;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorsUtil.secondaryLight, ColorsUtil.primaryLight],
  );

  @override
  Widget build(BuildContext context) {
    final photo = slide.photo;
    return Semantics(
      label: slide.subtitle == null
          ? slide.title
          : '${slide.title}, ${slide.subtitle}',
      button: slide.onTap != null,
      child: GestureDetector(
        onTap: slide.onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo == null)
              const DecoratedBox(decoration: BoxDecoration(gradient: _gradient))
            else
              Image.network(
                photo.url,
                headers: photoHeaders,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const DecoratedBox(
                        decoration: BoxDecoration(gradient: _gradient),
                      ),
                errorBuilder: (context, error, stack) => const DecoratedBox(
                  decoration: BoxDecoration(gradient: _gradient),
                ),
              ),
            // Darkens the bottom so the caption and credit stay readable on any photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (slide.subtitle != null)
                    Text(
                      slide.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            if (photo != null) PhotoCredit(photo: photo, bottom: 4, right: 10),
          ],
        ),
      ),
    );
  }
}

/// A photo's credit in the corner; tapping it opens the photo's page (Wikimedia Commons or the photographer on
/// Unsplash).
class PhotoCredit extends StatelessWidget {
  const PhotoCredit({
    super.key,
    required this.photo,
    required this.bottom,
    required this.right,
  });

  final Photo photo;
  final double bottom, right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      left: 16,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final uri = Uri.tryParse(photo.creditUrl);
          if (uri != null && uri.scheme == 'https') {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Text(
          photo.credit,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

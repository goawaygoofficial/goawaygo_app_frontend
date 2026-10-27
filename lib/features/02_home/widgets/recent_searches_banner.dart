import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/core/discover/recent_searches_store.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/photo_slider.dart';
import 'package:flutter/material.dart';

/// The home banner: the user's own last 5 searched places, each with a live photo of its top spot. Signed in,
/// the account keeps them; signed out, this device does. No searches yet: "No recent searches".
class RecentSearchesBanner extends StatefulWidget {
  const RecentSearchesBanner({
    super.key,
    required this.signedIn,
    required this.height,
    required this.onOpen,
  });

  final bool signedIn;
  final double height;
  final void Function(Place place) onOpen;

  @override
  State<RecentSearchesBanner> createState() => _RecentSearchesBannerState();
}

class _RecentSearchesBannerState extends State<RecentSearchesBanner> {
  List<BannerSlide>? _slides;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RecentSearchesBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn != widget.signedIn) _load();
  }

  Future<void> _load() async {
    final signedIn = widget.signedIn;
    final local = signedIn
        ? const <RecentSearch>[]
        : await RecentSearchesStore.read();
    List<BannerSlide> slides;
    try {
      slides = signedIn
          ? await DiscoverService.getRecentSearches()
          : await DiscoverService.getPhotosFor(local);
    } on ApiException {
      // Photos unavailable: still show this device's places, on plain slides.
      slides = [
        for (final search in local)
          BannerSlide(place: search.place, spot: search.spot),
      ];
    }
    if (mounted && signedIn == widget.signedIn) {
      setState(() => _slides = slides);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    if (slides == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }
    if (slides.isEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorsUtil.whiteColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No recent searches',
              style: TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Places you search for will show here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      );
    }
    return PhotoSlider(
      height: widget.height,
      slides: [
        for (final slide in slides)
          PhotoSlide(
            title: slide.place.name,
            subtitle: slide.spot != slide.place.name
                ? slide.spot
                : slide.place.country,
            photo: slide.photo,
            onTap: () => widget.onOpen(slide.place),
          ),
      ],
    );
  }
}

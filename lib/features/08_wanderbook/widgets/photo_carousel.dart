import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A post's photos, swiped sideways. They are the originals and are never cropped: each fits the frame whole
/// (frame shape from the first photo, between 4:5 and 1.91:1, like Instagram); "Full size" opens the file.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({super.key, required this.photos});

  final List<Photo> photos;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _page = 0;

  double get _ratio {
    final first = widget.photos.isEmpty ? null : widget.photos.first;
    if (first == null || first.height == 0) return 1;
    return (first.width / first.height).clamp(0.8, 1.91);
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _ratio,
            child: ColoredBox(
              color: Colors.black,
              child: PageView.builder(
                itemCount: photos.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => Image.network(
                  photos[index].url,
                  fit: BoxFit.contain,
                  semanticLabel: 'Photo ${index + 1} of ${photos.length}',
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                          ),
                        ),
                  errorBuilder: (context, error, stack) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (photos.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < photos.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _page
                              ? ColorsUtil.secondary
                              : Colors.white30,
                        ),
                      ),
                  ],
                ),
              if (photos.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(photos[_page].url),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text(
                      'Full size',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

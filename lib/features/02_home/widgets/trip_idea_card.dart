import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/photo_slider.dart';
import 'package:flutter/material.dart';

/// One idea: its photo (with credit), where it is, a short summary, tags, and Save to My Trips.
class TripIdeaCard extends StatefulWidget {
  const TripIdeaCard({
    super.key,
    required this.idea,
    required this.signedIn,
    required this.saved,
    required this.onOpen,
    required this.onSave,
    required this.onSignIn,
  });

  final TripIdea idea;
  final bool signedIn;
  final bool saved;
  final VoidCallback onOpen;
  final Future<void> Function(TripIdea idea) onSave;

  /// Saving needs an account: opens sign-in.
  final VoidCallback onSignIn;

  @override
  State<TripIdeaCard> createState() => _TripIdeaCardState();
}

class _TripIdeaCardState extends State<TripIdeaCard> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _save() async {
    if (!widget.signedIn) {
      widget.onSignIn();
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(widget.idea);
      Analytics.track(TripIdeaSaved(hiddenGem: widget.idea.hiddenGem));
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _saveLabel {
    if (widget.saved) return tr('Saved');
    if (_saving) return tr('Saving…');
    if (_failed) return tr('Try again');
    return widget.signedIn ? tr('Save to My Trips') : tr('Sign in to save');
  }

  @override
  Widget build(BuildContext context) {
    final idea = widget.idea;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorsUtil.secondaryLight, ColorsUtil.secondaryDark],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              idea.photo.url,
              headers: photoHeaders,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
            // Keeps the text readable on any photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xC0000000),
                    Color(0x1A000000),
                    Color(0x59000000),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea.where.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        idea.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        idea.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (idea.category.isNotEmpty) _Tag(idea.category),
                          if (idea.hiddenGem) _Tag(tr('Hidden gem')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: widget.saved
                    ? ColorsUtil.secondary
                    : Colors.white.withValues(alpha: 0.9),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: widget.saved || _saving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.saved ? Icons.bookmark : Icons.bookmark_border,
                          size: 18,
                          color: widget.saved
                              ? ColorsUtil.whiteColor
                              : ColorsUtil.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _saveLabel,
                          style: TextStyle(
                            color: widget.saved
                                ? ColorsUtil.whiteColor
                                : ColorsUtil.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PhotoCredit(photo: idea.photo, bottom: 4, right: 14),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.isEmpty ? label : label[0].toUpperCase() + label.substring(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

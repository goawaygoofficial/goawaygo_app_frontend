import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/features/06_destinationInfo/utils/card_meta.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// One of the nine AI cards: tap to expand. A card with nothing checked and valid says so and doesn't open.
class InfoCardTile extends StatefulWidget {
  const InfoCardTile({super.key, required this.card});

  final InfoCard card;

  @override
  State<InfoCardTile> createState() => _InfoCardTileState();
}

class _InfoCardTileState extends State<InfoCardTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final meta = cardMeta[card.id];
    if (meta == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ColorsUtil.secondary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Semantics(
            expanded: card.available ? _open : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: card.available
                  ? () => setState(() => _open = !_open)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Opacity(
                  opacity: card.available ? 1 : 0.7,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ColorsUtil.primary,
                        radius: 22,
                        child: Icon(
                          meta.icon,
                          color: ColorsUtil.whiteColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta.title,
                              style: const TextStyle(
                                color: ColorsUtil.whiteColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.available
                                  ? meta.subtitle
                                  : 'Not available right now',
                              style: const TextStyle(
                                color: ColorsUtil.whiteLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (card.available)
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(
                            Icons.expand_more_rounded,
                            color: ColorsUtil.whiteColor,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _Items(card: card),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.card});

  final InfoCard card;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorsUtil.whiteColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < card.items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 24, color: ColorsUtil.whiteLight),
                _Item(item: card.items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          card.id == 'visa'
              ? 'Rules change: always check official sources before you travel. AI-generated, may contain '
                    'mistakes.'
              : 'AI-generated, may contain mistakes.',
          style: const TextStyle(color: ColorsUtil.whiteLight, fontSize: 12),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item});

  final CardItem item;

  /// "https://www.indianvisaonline.gov.in/evisa" → "indianvisaonline.gov.in"
  static String _siteName(String link) {
    final host = Uri.tryParse(link)?.host ?? '';
    return host.isEmpty ? 'Official site' : host.replaceFirst('www.', '');
  }

  @override
  Widget build(BuildContext context) {
    final link = item.link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: const TextStyle(
            color: ColorsUtil.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.detail,
          style: const TextStyle(
            color: ColorsUtil.primary,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        if (item.mayChange || link != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (item.mayChange)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ColorsUtil.secondaryLighter,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'May vary, check before you go',
                      style: TextStyle(
                        color: ColorsUtil.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (link != null)
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(link),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _siteName(link),
                          style: const TextStyle(
                            color: ColorsUtil.secondaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: ColorsUtil.secondaryDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: ColorsUtil.secondaryDark,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

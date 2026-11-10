import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a partner page in the phone's browser (where the partner's own app may take over).
Future<void> openPartner(String link) async {
  final uri = Uri.tryParse(link);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// The founder's result card: two orange halves, the lighter one on the left (also the trip plan's cards).
class TwoToneCard extends StatelessWidget {
  const TwoToneCard({
    super.key,
    required this.left,
    required this.right,
    this.onTap,
  });

  final List<Widget> left;
  final List<Widget> right;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: ColorsUtil.secondaryDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 9,
                    child: Container(
                      color: ColorsUtil.secondaryLight,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: left,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 11,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: right,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _big = TextStyle(
  color: ColorsUtil.whiteColor,
  fontSize: 17,
  fontWeight: FontWeight.bold,
);
const _title = TextStyle(
  color: ColorsUtil.whiteColor,
  fontSize: 15,
  fontWeight: FontWeight.bold,
);
final _small = TextStyle(
  color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
  fontSize: 12,
);
final _line = TextStyle(
  color: ColorsUtil.whiteColor.withValues(alpha: 0.85),
  fontSize: 13,
);

/// One fare: price and airline on the light side; departure, route, stops and flying time on the dark side.
class FareCard extends StatelessWidget {
  const FareCard({
    super.key,
    required this.fare,
    required this.currency,
    required this.roundTrip,
    required this.onOpen,
  });

  final Fare fare;
  final String currency;
  final bool roundTrip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final stops = roundTrip && fare.returnStops != null
        ? tr('{0} · back {1}', [
            BookFormat.stops(fare.stops),
            BookFormat.stops(fare.returnStops!).toLowerCase(),
          ])
        : BookFormat.stops(fare.stops);
    final duration = !roundTrip && fare.durationMinutes != null
        ? '${BookFormat.duration(fare.durationMinutes!)} · '
        : '';
    return Semantics(
      link: true,
      child: TwoToneCard(
        onTap: onOpen,
        left: [
          Text(BookFormat.price(fare.price, currency), style: _big),
          const SizedBox(height: 2),
          Text(
            '${roundTrip ? 'Round trip' : 'One way'} per passenger',
            style: _small,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipOval(
                child: Container(
                  color: ColorsUtil.whiteColor,
                  width: 26,
                  height: 26,
                  child: Image.network(
                    'https://pics.avs.io/64/64/${Uri.encodeComponent(fare.airline)}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fare.airlineName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColorsUtil.whiteColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        right: [
          Text(
            '${BookFormat.time(fare.departAt)} · ${BookFormat.day(fare.departAt)}',
            style: _title,
          ),
          const SizedBox(height: 4),
          Text(
            '${fare.origin} → ${fare.destination}'
            '${roundTrip && fare.returnAt != null ? ' · back ${BookFormat.day(fare.returnAt!)}' : ''}',
            style: _line,
          ),
          const SizedBox(height: 4),
          Text('$duration$stops', style: _line),
        ],
      ),
    );
  }
}

/// A partner (the founder's stay and car cards, without prices until a partner gives us live ones).
class PartnerCardTile extends StatelessWidget {
  const PartnerCardTile({
    super.key,
    required this.partner,
    required this.kind,
    required this.title,
    required this.detail,
    required this.onOpen,
  });

  final PartnerCard partner;

  /// Under the partner's name ("Hotels in Jaipur").
  final String kind;

  /// Right side, bold ("See hotels for 7–9 Dec").
  final String title;
  final String detail;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: TwoToneCard(
        onTap: onOpen,
        left: [
          // Long names ("EconomyBookings") shrink to fit the light half on one line.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(partner.name, style: _big, maxLines: 1),
          ),
          const SizedBox(height: 4),
          Text(kind, style: _small),
          const SizedBox(height: 2),
          Text(tr('Prices on {0}', [partner.name]), style: _small),
        ],
        right: [
          Text(title, style: _title),
          const SizedBox(height: 4),
          Text(detail, style: _line),
        ],
      ),
    );
  }
}

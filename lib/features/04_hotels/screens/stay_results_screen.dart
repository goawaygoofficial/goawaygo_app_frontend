import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/book/book_service.dart';
import 'package:app_frontend/global_widgets/book/book_cards.dart';
import 'package:app_frontend/global_widgets/book/results_layout.dart';
import 'package:flutter/material.dart';

/// Stay results: hotel partners (those that allow apps) opened on the place, dates and guests. No hotel prices
/// here yet (no free source); they arrive with a live partner, in the founder's hotel cards.
class StayResultsScreen extends StatefulWidget {
  const StayResultsScreen({super.key, required this.search});

  final StaySearch search;

  @override
  State<StayResultsScreen> createState() => _StayResultsScreenState();
}

class _StayResultsScreenState extends State<StayResultsScreen> {
  late Future<List<PartnerCard>> _partners = BookService.stayPartners(
    widget.search,
  );

  @override
  Widget build(BuildContext context) {
    final search = widget.search;
    final dates = BookFormat.dateRange(search.checkin, search.checkout);
    return FutureBuilder<List<PartnerCard>>(
      future: _partners,
      builder: (context, snapshot) {
        final partners = snapshot.data;
        return ResultsLayout(
          icon: Icons.hotel,
          title: tr('Stays'),
          heading: search.place,
          dates: dates,
          travellers:
              '${BookFormat.plural(search.adults, 'guest')} · ${BookFormat.plural(search.rooms, 'room')}',
          note: tr(
            'Hotels and prices open on the partner\'s site, with your dates filled in',
          ),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              ResultsMessage(title: tr('Opening hotel partners…'))
            else if (snapshot.hasError || partners == null)
              ResultsMessage(
                title: tr('Hotel partners didn\'t open'),
                text:
                    snapshot.error?.toString() ??
                    tr('Could not open hotel partners.'),
                onRetry: () => setState(
                  () => _partners = BookService.stayPartners(search),
                ),
              )
            else if (partners.isEmpty)
              ResultsMessage(
                title: tr('No hotel partners here yet'),
                text: tr('Please try again later.'),
              )
            else
              for (final partner in partners)
                PartnerCardTile(
                  partner: partner,
                  kind: tr('Hotels in {0}', [search.place]),
                  title: tr('See hotels for {0}', [dates]),
                  detail: partner.id == 'tripcom'
                      ? tr('Pick {0} from Trip.com\'s list to see hotels', [
                          search.place,
                        ])
                      : tr('Your dates and guests are filled in'),
                  onOpen: () {
                    Analytics.track(
                      PartnerOpened(TravelCategory.stays, partner.id),
                    );
                    openPartner(partner.link);
                  },
                ),
          ],
        );
      },
    );
  }
}

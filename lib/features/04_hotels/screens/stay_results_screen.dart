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
          title: 'Stays',
          heading: search.place,
          dates: dates,
          travellers:
              '${BookFormat.plural(search.adults, 'guest')} · ${BookFormat.plural(search.rooms, 'room')}',
          note: "Hotels and prices open on the partner's site, with your dates filled in",
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const ResultsMessage(title: 'Opening hotel partners…')
            else if (snapshot.hasError || partners == null)
              ResultsMessage(
                title: "Hotel partners didn't open",
                text:
                    snapshot.error?.toString() ??
                    'Could not open hotel partners.',
                onRetry: () => setState(
                  () => _partners = BookService.stayPartners(search),
                ),
              )
            else if (partners.isEmpty)
              const ResultsMessage(
                title: 'No hotel partners here yet',
                text: 'Please try again later.',
              )
            else
              for (final partner in partners)
                PartnerCardTile(
                  partner: partner,
                  kind: 'Hotels in ${search.place}',
                  title: 'See hotels for $dates',
                  detail: partner.id == 'tripcom'
                      ? "Pick ${search.place} from Trip.com's list to see hotels"
                      : 'Your dates and guests are filled in',
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

import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/book/book_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/book/book_cards.dart';
import 'package:app_frontend/global_widgets/book/results_layout.dart';
import 'package:flutter/material.dart';

/// Flight results (the founder's design): recent fares on the date asked and on cheaper dates that month, each
/// opening on Aviasales, and a floating "See all flights" for Aviasales' live search. Recent prices, so labelled
/// "may change".
class FlightResultsScreen extends StatefulWidget {
  const FlightResultsScreen({super.key, required this.search});

  final FlightSearch search;

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  late Future<FlightResults> _results = BookService.searchFlights(
    widget.search,
  );

  void _open(String link) {
    Analytics.track(PartnerOpened(TravelCategory.flights, 'aviasales'));
    openPartner(link);
  }

  @override
  Widget build(BuildContext context) {
    final search = widget.search;
    final roundTrip = search.returnDate != null;
    return FutureBuilder<FlightResults>(
      future: _results,
      builder: (context, snapshot) {
        final results = snapshot.data;
        return ResultsLayout(
          icon: Icons.flight,
          title: 'Flights',
          heading: '${search.from.name} to ${search.to.name}',
          dates: roundTrip
              ? '${BookFormat.day(search.depart)} – ${BookFormat.day(search.returnDate!)}'
              : BookFormat.day(search.depart),
          travellers: BookFormat.plural(search.adults, 'passenger'),
          note:
              'Recent prices travellers found · they may change until you book',
          floating: results == null
              ? null
              : FloatingPill(
                  label: 'See all flights',
                  onPressed: () => _open(results.searchLink),
                ),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const ResultsMessage(title: 'Finding fares…')
            else if (snapshot.hasError || results == null)
              ResultsMessage(
                title: 'No fares right now',
                text:
                    snapshot.error?.toString() ??
                    'Could not find flight prices.',
                onRetry: () => setState(
                  () => _results = BookService.searchFlights(search),
                ),
              )
            else ...[
              _Section('On ${BookFormat.day(search.depart)}'),
              if (results.onDate.isEmpty)
                ResultsMessage(
                  title: 'No recent price for this date',
                  text: 'Nobody searched this trip lately. See live prices for it on Aviasales.',
                  action: FloatingPill(
                    label: 'See live prices',
                    onPressed: () => _open(results.searchLink),
                  ),
                )
              else
                for (final fare in results.onDate)
                  FareCard(
                    fare: fare,
                    currency: results.currency,
                    roundTrip: roundTrip,
                    onOpen: () => _open(fare.link),
                  ),
              if (results.nearby.isNotEmpty) ...[
                _Section('Other dates in ${BookFormat.month(search.depart)}'),
                for (final fare in results.nearby)
                  FareCard(
                    fare: fare,
                    currency: results.currency,
                    roundTrip: roundTrip,
                    onOpen: () => _open(fare.link),
                  ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: ColorsUtil.whiteColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

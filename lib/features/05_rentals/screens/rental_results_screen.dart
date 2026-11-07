import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/book/book_service.dart';
import 'package:app_frontend/global_widgets/book/book_cards.dart';
import 'package:app_frontend/global_widgets/book/results_layout.dart';
import 'package:flutter/material.dart';

/// Car rental results: rental comparison partners for the pick-up place. No car prices here yet (no free source);
/// they arrive with a live partner, in the founder's car cards.
class RentalResultsScreen extends StatefulWidget {
  const RentalResultsScreen({super.key, required this.search});

  final CarSearch search;

  @override
  State<RentalResultsScreen> createState() => _RentalResultsScreenState();
}

class _RentalResultsScreenState extends State<RentalResultsScreen> {
  late Future<List<PartnerCard>> _partners = BookService.carPartners(
    widget.search,
  );

  @override
  Widget build(BuildContext context) {
    final search = widget.search;
    final dates = BookFormat.dateRange(search.pickup, search.dropoff);
    return FutureBuilder<List<PartnerCard>>(
      future: _partners,
      builder: (context, snapshot) {
        final partners = snapshot.data;
        return ResultsLayout(
          icon: Icons.directions_car,
          title: 'Car Rentals',
          heading: search.place,
          dates: dates,
          note:
              "Cars and prices open on the partner's site; compare them there",
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const ResultsMessage(title: 'Opening rental partners…')
            else if (snapshot.hasError || partners == null)
              ResultsMessage(
                title: "Rental partners didn't open",
                text:
                    snapshot.error?.toString() ??
                    'Could not open car rental partners.',
                onRetry: () =>
                    setState(() => _partners = BookService.carPartners(search)),
              )
            else if (partners.isEmpty)
              const ResultsMessage(
                title: 'No rental partners here yet',
                text: 'Please try again later.',
              )
            else
              for (final partner in partners)
                PartnerCardTile(
                  partner: partner,
                  kind: 'Car rental comparison',
                  title: 'Cars in ${search.place}',
                  detail:
                      partner.id == 'economybookings' && search.airport != null
                      ? 'Opens on ${search.airport} airport; add your dates ($dates)'
                      : 'Enter ${search.place} and $dates there',
                  onOpen: () {
                    Analytics.track(
                      PartnerOpened(TravelCategory.rentals, partner.id),
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

import 'package:app_frontend/core/i18n/i18n.dart';
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
          title: tr('Car Rentals'),
          heading: search.place,
          dates: dates,
          note: tr(
            'Cars and prices open on the partner\'s site; compare them there',
          ),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              ResultsMessage(title: tr('Opening rental partners…'))
            else if (snapshot.hasError || partners == null)
              ResultsMessage(
                title: tr('Rental partners didn\'t open'),
                text:
                    snapshot.error?.toString() ??
                    tr('Could not open car rental partners.'),
                onRetry: () =>
                    setState(() => _partners = BookService.carPartners(search)),
              )
            else if (partners.isEmpty)
              ResultsMessage(
                title: tr('No rental partners here yet'),
                text: tr('Please try again later.'),
              )
            else
              for (final partner in partners)
                PartnerCardTile(
                  partner: partner,
                  kind: tr('Car rental comparison'),
                  title: tr('Cars in {0}', [search.place]),
                  detail:
                      partner.id == 'economybookings' && search.airport != null
                      ? tr('Opens on {0} airport; add your dates ({1})', [
                          search.airport,
                          dates,
                        ])
                      : tr('Enter {0} and {1} there', [search.place, dates]),
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

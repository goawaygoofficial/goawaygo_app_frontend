import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/core/discover/recent_searches_store.dart';
import 'package:app_frontend/core/plans/plan_models.dart';
import 'package:app_frontend/features/06_destinationInfo/widgets/info_card_tile.dart';
import 'package:app_frontend/features/06_destinationInfo/widgets/travel_loader.dart';
import 'package:app_frontend/features/10_plans/screens/plan_form_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/photo_slider.dart';
import 'package:app_frontend/global_widgets/pill_button.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A destination: a banner of its tourist spots and nine AI-written info cards. The whole page appears at once,
/// after a travel animation, when everything is ready.
class DestinationInfoScreen extends StatefulWidget {
  final DestinationRequest request;
  final VoidCallback onClose;

  const DestinationInfoScreen({
    super.key,
    required this.request,
    required this.onClose,
  });

  @override
  State<DestinationInfoScreen> createState() => _DestinationInfoScreenState();
}

enum _Failure { notFound, error }

class _DestinationInfoScreenState extends State<DestinationInfoScreen> {
  DestinationPage? _page;
  _Failure? _failure;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Try again: back to the travel animation (nothing to reset on the first load).
    if (_page != null || _failure != null) {
      setState(() {
        _page = null;
        _failure = null;
      });
    }
    final signedIn =
        Provider.of<UserProvider>(context, listen: false).user != null;
    try {
      final page = await DiscoverService.getDestination(widget.request);
      if (!mounted) return;
      setState(() => _page = page);
      // Signed in, the account keeps the search; signed out, this device does.
      if (!signedIn && page.status != DestinationStatus.unknown) {
        await RecentSearchesStore.remember(
          page.place,
          page.spots.isEmpty ? null : page.spots.first.name,
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error.statusCode == 404 ? _Failure.notFound : _Failure.error;
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', height: height * 0.1),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: ColorsUtil.whiteColor,
                    ),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(child: _body(height)),
          ],
        ),
      ),
    );
  }

  Widget _body(double height) {
    final page = _page;
    if (_failure == _Failure.notFound) {
      return _Message(
        title: "We couldn't find that place",
        text:
            'Check the spelling of “${widget.request.name}”, or pick a place from the suggestions while you '
            'type.',
        action: 'Search again',
        onAction: widget.onClose,
      );
    }
    if (_failure == _Failure.error) {
      return _Message(
        title: 'Something went wrong',
        text: _errorMessage,
        action: 'Try again',
        onAction: _load,
      );
    }
    if (page == null) {
      return Center(child: TravelLoader(place: widget.request.name));
    }
    if (page.status == DestinationStatus.unknown) {
      return _Message(
        title: "We don't know ${page.place.name} well enough yet",
        text: 'Try the nearest city or a better-known place nearby.',
        action: 'Search again',
        onAction: widget.onClose,
      );
    }

    final slides = page.spots.isEmpty
        ? [PhotoSlide(title: page.place.name)]
        : [
            for (final spot in page.spots)
              PhotoSlide(title: spot.name, photo: spot.photo),
          ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          page.place.name.toUpperCase(),
          style: const TextStyle(
            color: ColorsUtil.whiteColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        if (page.place.context.isNotEmpty)
          Text(
            page.place.context,
            style: TextStyle(
              color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
              fontSize: 15,
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: PillButton(
            label: 'Plan a trip here',
            icon: Icons.travel_explore,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    PlanFormScreen(place: PlanPlace.fromPlace(page.place)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PhotoSlider(slides: slides, height: height * 0.28),
        const SizedBox(height: 16),
        if (page.status == DestinationStatus.busy)
          _Busy(onRetry: _load)
        else
          for (final card in page.cards) InfoCardTile(card: card),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Our travel guide is busy right now',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorsUtil.whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lots of people are exploring at the moment. Please try again in a minute.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorsUtil.whiteColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          PillButton(label: 'Try again', onPressed: onRetry, large: true),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String title, text, action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.travel_explore,
              size: 40,
              color: ColorsUtil.secondaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            PillButton(label: action, onPressed: onAction, large: true),
          ],
        ),
      ),
    );
  }
}

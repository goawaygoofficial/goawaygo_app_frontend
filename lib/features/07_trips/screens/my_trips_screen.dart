import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/core/plans/plan_models.dart';
import 'package:app_frontend/core/plans/plan_service.dart';
import 'package:app_frontend/features/06_destinationInfo/screens/destination_info_screen.dart';
import 'package:app_frontend/features/10_plans/screens/plan_form_screen.dart';
import 'package:app_frontend/features/10_plans/screens/plan_screen.dart';
import 'package:app_frontend/features/10_plans/widgets/plan_widgets.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/book/book_cards.dart';
import 'package:app_frontend/global_widgets/pill_button.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// My Trips: trip plans and the places saved from "Ideas for your next trip" (sign-in needed), the same as the
/// website's.
class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({
    super.key,
    required this.onPlanTrip,
    required this.onSignIn,
    required this.toggleBottomBar,
  });

  /// Opens Home, where the ideas are.
  final VoidCallback onPlanTrip;

  /// Opens the Profile tab to sign in.
  final VoidCallback onSignIn;
  final void Function(bool) toggleBottomBar;

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  static const _tones = [
    [ColorsUtil.secondaryLight, ColorsUtil.secondaryDark],
    [ColorsUtil.secondary, ColorsUtil.secondaryDark],
    [ColorsUtil.secondaryLighter, ColorsUtil.secondary],
    [ColorsUtil.secondaryLight, ColorsUtil.primaryLight],
  ];

  List<SavedPlace>? _places;
  List<PlanSummary>? _plans;
  String? _error;
  int? _loadedFor;
  DestinationRequest? _destination;
  bool _showDestination = false;

  void _sync(int? userId) {
    if (userId == _loadedFor) return;
    _loadedFor = userId;
    _places = null;
    _plans = null;
    _error = null;
    if (userId != null) _load(userId);
  }

  @override
  void initState() {
    super.initState();
    PlanService.changes.addListener(_reloadPlans);
  }

  @override
  void dispose() {
    PlanService.changes.removeListener(_reloadPlans);
    super.dispose();
  }

  /// A plan was made, changed or deleted (here or from a destination on Home).
  Future<void> _reloadPlans() async {
    final userId = _loadedFor;
    if (userId == null) return;
    try {
      final plans = await PlanService.list();
      if (mounted && _loadedFor == userId) setState(() => _plans = plans);
    } on ApiException {
      // Keep the list shown; it reloads with the next change or visit.
    }
  }

  Future<void> _load(int userId) async {
    try {
      // Both at once; a failure of either shows its error.
      final results = await Future.wait<Object>([
        DiscoverService.listSavedPlaces(),
        PlanService.list(),
      ]);
      if (mounted && _loadedFor == userId) {
        setState(() {
          _places = results[0] as List<SavedPlace>;
          _plans = results[1] as List<PlanSummary>;
        });
      }
    } on ApiException catch (error) {
      if (mounted && _loadedFor == userId) {
        setState(() => _error = error.message);
      }
    }
  }

  Future<void> _remove(SavedPlace place) async {
    try {
      await DiscoverService.removeSavedPlace(place.id);
      if (mounted) {
        setState(
          () => _places = _places?.where((p) => p.id != place.id).toList(),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _open(SavedPlace place) {
    setState(() {
      _destination = DestinationRequest.text(
        place.name,
        '${place.name}, ${place.country}',
      );
      _showDestination = true;
      widget.toggleBottomBar(false);
    });
  }

  void _openPlan(PlanSummary plan) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => PlanScreen(id: plan.id)));

  void _planTrip(SavedPlace place) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlanFormScreen(place: PlanPlace.fromSaved(place)),
    ),
  );

  /// Called by Back (starts the slide out) and again by the panel when the slide out has finished.
  void _close() {
    if (_showDestination) {
      setState(() => _showDestination = false);
      widget.toggleBottomBar(true);
    } else {
      setState(() => _destination = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    _sync(user?.id);

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: Stack(
        children: [
          SafeArea(child: _body(context, signedIn: user != null)),
          SlideFadeTransition(
            visible: _showDestination,
            onClose: _close,
            child: _destination == null
                ? const SizedBox.shrink()
                : DestinationInfoScreen(
                    request: _destination!,
                    onClose: _close,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, {required bool signedIn}) {
    final places = _places;
    final plans = _plans;
    if (!signedIn) {
      return _EmptyState(
        title: 'SAVE PLACES YOU LOVE',
        text: 'Sign in to keep places from Ideas for your next trip and trip plans in My Trips.',
        action: 'Sign in',
        onAction: widget.onSignIn,
      );
    }
    if (_error != null) {
      return _EmptyState(
        title: 'MY TRIPS',
        text: _error!,
        action: 'Try again',
        onAction: () {
          setState(() => _error = null);
          _load(_loadedFor!);
        },
      );
    }
    if (places == null || plans == null) {
      return const Center(
        child: CircularProgressIndicator(color: ColorsUtil.whiteColor),
      );
    }
    if (places.isEmpty && plans.isEmpty) {
      return _EmptyState(
        title: 'NO TRIPS YET',
        text:
            'Save places from Ideas for your next trip on Home, or plan a trip from any destination, and '
            "they'll show up here.",
        action: 'Find ideas',
        onAction: widget.onPlanTrip,
      );
    }

    final height = MediaQuery.of(context).size.height;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset('assets/images/logo.png', height: height * 0.1),
        ),
        const SizedBox(height: 8),
        const Text(
          'MY TRIPS',
          style: TextStyle(
            color: ColorsUtil.whiteColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        if (plans.isNotEmpty) ...[
          const _Subheading('Trip plans'),
          for (final plan in plans)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(plan: plan, onOpen: () => _openPlan(plan)),
            ),
        ],
        if (places.isNotEmpty) ...[
          const _Subheading('Saved places'),
          for (var i = 0; i < places.length; i++)
            _SavedPlaceCard(
              place: places[i],
              colors: _tones[i % _tones.length],
              onOpen: () => _open(places[i]),
              onPlan: () => _planTrip(places[i]),
              onRemove: () => _remove(places[i]),
            ),
        ],
      ],
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: ColorsUtil.whiteColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A trip plan, on the founder's two-tone card: the place on the left, the plan's title and dates on the right.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onOpen});

  final PlanSummary plan;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final end = PlanService.endDate(plan.startDate, plan.days);
    final small = TextStyle(
      color: ColorsUtil.whiteColor.withValues(alpha: 0.85),
      fontSize: 13,
    );
    return Semantics(
      button: true,
      child: TwoToneCard(
        onTap: onOpen,
        left: [
          Text(
            plan.placeName,
            style: const TextStyle(
              color: ColorsUtil.whiteColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (plan.country.isNotEmpty) Text(plan.country, style: small),
        ],
        right: [
          Text(
            plan.title,
            style: const TextStyle(
              color: ColorsUtil.whiteColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              planDates(plan.startDate, end),
              BookFormat.plural(plan.days, 'day'),
              if (plan.shared) 'Shared',
            ].join(' · '),
            style: small,
          ),
        ],
      ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({
    required this.place,
    required this.colors,
    required this.onOpen,
    required this.onPlan,
    required this.onRemove,
  });

  final SavedPlace place;
  final List<Color> colors;
  final VoidCallback onOpen;
  final VoidCallback onPlan;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.where.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (place.category.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.category[0].toUpperCase() +
                                place.category.substring(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _PlanTripButton(onPressed: onPlan),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove ${place.name} from My Trips',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The small white pill on a saved place that opens the plan form for it.
class _PlanTripButton extends StatelessWidget {
  const _PlanTripButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.travel_explore, size: 18),
      label: const Text('Plan a trip'),
      style: TextButton.styleFrom(
        backgroundColor: ColorsUtil.whiteColor,
        foregroundColor: ColorsUtil.primary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: const Size(0, 36),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String title, text, action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return SingleChildScrollView(
      padding: EdgeInsets.all(width * 0.04),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Image.asset('assets/images/logo.png', height: height * 0.12),
          ),
          SizedBox(height: height * 0.06),
          Container(
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: ColorsUtil.secondaryLight,
              borderRadius: BorderRadius.circular(width * 0.04),
            ),
            child: Image.asset(
              'assets/icons/mytrips_white.png',
              height: height * 0.06,
              width: height * 0.06,
            ),
          ),
          SizedBox(height: height * 0.025),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColorsUtil.whiteColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: height * 0.015),
          SizedBox(
            width: width * 0.7,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: height * 0.03),
          PillButton(label: action, onPressed: onAction, large: true),
        ],
      ),
    );
  }
}

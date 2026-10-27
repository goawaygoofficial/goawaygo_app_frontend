import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/features/06_destinationInfo/screens/destination_info_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// My Trips: the places saved from "Ideas for your next trip" (sign-in needed), the same as the website's.
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
  String? _error;
  int? _loadedFor;
  DestinationRequest? _destination;
  bool _showDestination = false;

  void _sync(int? userId) {
    if (userId == _loadedFor) return;
    _loadedFor = userId;
    _places = null;
    _error = null;
    if (userId != null) _load(userId);
  }

  Future<void> _load(int userId) async {
    try {
      final places = await DiscoverService.listSavedPlaces();
      if (mounted && _loadedFor == userId) setState(() => _places = places);
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
    if (!signedIn) {
      return _EmptyState(
        title: 'SAVE PLACES YOU LOVE',
        text:
            'Sign in to keep places from Ideas for your next trip in My Trips.',
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
    if (places == null) {
      return const Center(
        child: CircularProgressIndicator(color: ColorsUtil.whiteColor),
      );
    }
    if (places.isEmpty) {
      return _EmptyState(
        title: 'NO TRIPS YET',
        text: "Save places from Ideas for your next trip on Home, and they'll show up here.",
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
        const SizedBox(height: 12),
        for (var i = 0; i < places.length; i++)
          _SavedPlaceCard(
            place: places[i],
            colors: _tones[i % _tones.length],
            onOpen: () => _open(places[i]),
            onRemove: () => _remove(places[i]),
          ),
      ],
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({
    required this.place,
    required this.colors,
    required this.onOpen,
    required this.onRemove,
  });

  final SavedPlace place;
  final List<Color> colors;
  final VoidCallback onOpen;
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
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsUtil.secondary,
              foregroundColor: ColorsUtil.whiteColor,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.1,
                vertical: height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              action,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

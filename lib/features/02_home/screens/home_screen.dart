import 'dart:async';

import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/features/02_home/widgets/category_button.dart';
import 'package:app_frontend/features/02_home/widgets/place_search_field.dart';
import 'package:app_frontend/features/02_home/widgets/recent_searches_banner.dart';
import 'package:app_frontend/features/02_home/widgets/stacked_card_carousel.dart';
import 'package:app_frontend/features/02_home/widgets/trip_idea_card.dart';
import 'package:app_frontend/features/03_flights/screens/flight_search_screen.dart';
import 'package:app_frontend/features/04_hotels/screens/hotels_search_screen.dart';
import 'package:app_frontend/features/05_rentals/screens/rentals_search_screen.dart';
import 'package:app_frontend/features/06_destinationInfo/screens/destination_info_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final void Function(bool) toggleBottomBar;
  final UserModel? user;

  /// Opens the Profile tab, where the user signs in (to save ideas).
  final VoidCallback onOpenProfile;

  const HomeScreen({
    super.key,
    required this.toggleBottomBar,
    required this.onOpenProfile,
    this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _showFlightSearch = false;
  bool _showHotelsSearch = false;
  bool _showRentalSearch = false;
  bool _showDestinationInfo = false;

  /// The open destination page, if any.
  DestinationRequest? _destination;

  /// Random ideas for the next trip, replaced every minute; null until the first set arrives.
  List<TripIdea>? _ideas;
  Timer? _ideasTimer;
  static const _ideaCount = 6;

  /// Keys of the places in My Trips (signed in), to show which ideas are saved.
  Set<String> _savedKeys = const {};
  int? _savedFor;

  /// Changed after a destination page closes, so the banner shows the new search.
  int _bannerVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
    _ideasTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Only while the app is on screen.
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _loadIdeas();
      }
    });
  }

  @override
  void dispose() {
    _ideasTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIdeas() async {
    try {
      final ideas = await DiscoverService.getTripIdeas(_ideaCount);
      // Keep showing the current set if the backend has none right now.
      if (mounted && (ideas.isNotEmpty || _ideas == null)) {
        setState(() => _ideas = ideas);
      }
    } on ApiException {
      if (mounted && _ideas == null) setState(() => _ideas = const []);
    }
  }

  /// Loads the saved keys once per signed-in user.
  void _syncSaved(int? userId) {
    if (userId == _savedFor) return;
    _savedFor = userId;
    _savedKeys = const {};
    if (userId == null) return;
    DiscoverService.listSavedPlaces()
        .then((places) {
          if (mounted && _savedFor == userId) {
            setState(() => _savedKeys = {for (final p in places) p.key});
          }
        })
        .catchError((Object _) {});
  }

  Future<void> _saveIdea(TripIdea idea) async {
    await DiscoverService.saveIdea(idea);
    if (mounted) setState(() => _savedKeys = {..._savedKeys, idea.id});
  }

  void _openDestination(DestinationRequest request) {
    FocusManager.instance.primaryFocus?.unfocus();
    Analytics.track(const DestinationSearched());
    setState(() {
      _destination = request;
      _showDestinationInfo = true;
      widget.toggleBottomBar(false);
    });
  }

  /// Called by Back (starts the slide out) and again by the panel when the slide out has finished.
  void _closeDestination() {
    if (_showDestinationInfo) {
      setState(() {
        _showDestinationInfo = false;
        _searchController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
        widget.toggleBottomBar(true);
      });
    } else {
      // Off screen now: drop the page, and show the new search in the banner.
      setState(() {
        _destination = null;
        _bannerVersion++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final user = context.watch<UserProvider>().user;
    _syncSaved(user?.id);
    final ideas = _ideas;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight:
                      height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                width: width,
                padding: EdgeInsets.all(width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: height * 0.12,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.notifications,
                            size: width * 0.075,
                            color: ColorsUtil.secondaryLight,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    // Category Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CategoryButton(
                          title: 'Flights',
                          imagePath: 'assets/images/flights.png',
                          onTap: () {
                            Analytics.track(
                              TravelCategoryOpened(TravelCategory.flights),
                            );
                            setState(() {
                              _showFlightSearch = true;
                              widget.toggleBottomBar(false);
                            });
                          },
                        ),
                        CategoryButton(
                          title: 'Stays',
                          imagePath: 'assets/images/stays.png',
                          onTap: () {
                            Analytics.track(
                              TravelCategoryOpened(TravelCategory.stays),
                            );
                            setState(() {
                              _showHotelsSearch = true;
                              widget.toggleBottomBar(false);
                            });
                          },
                        ),
                        CategoryButton(
                          title: 'Rentals',
                          imagePath: 'assets/images/rentals.png',
                          onTap: () {
                            Analytics.track(
                              TravelCategoryOpened(TravelCategory.rentals),
                            );
                            setState(() {
                              _showRentalSearch = true;
                              widget.toggleBottomBar(false);
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.025),
                    // Search Field
                    PlaceSearchField(
                      controller: _searchController,
                      onPick: (place) =>
                          _openDestination(DestinationRequest.place(place)),
                      onSearch: (text) {
                        if (text.length >= 2) {
                          _openDestination(DestinationRequest.text(text));
                        }
                      },
                    ),
                    SizedBox(height: height * 0.015),

                    // Search Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          final text = _searchController.text.trim();
                          if (text.length >= 2) {
                            _openDestination(DestinationRequest.text(text));
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsUtil.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(width * 0.075),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.15,
                            vertical: height * 0.015,
                          ),
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(
                            color: ColorsUtil.whiteColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.03),

                    // Your recent searches
                    RecentSearchesBanner(
                      key: ValueKey(_bannerVersion),
                      signedIn: user != null,
                      height: height * 0.23,
                      onOpen: (place) =>
                          _openDestination(DestinationRequest.place(place)),
                    ),
                    SizedBox(height: height * 0.025),

                    // Recommendations
                    const Text(
                      'IDEAS FOR YOUR NEXT TRIP ...',
                      style: TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: height * 0.015),

                    if (ideas == null || ideas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          ideas == null ? 'Finding ideas…' : 'New ideas are on their way. Check back in a minute.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColorsUtil.whiteColor.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      )
                    else
                      StackedCardCarousel(
                        height: width * 0.78,
                        itemCount: ideas.length,
                        itemBuilder: (context, index) {
                          final idea = ideas[index];
                          return TripIdeaCard(
                            key: ValueKey(idea.id),
                            idea: idea,
                            signedIn: user != null,
                            saved: _savedKeys.contains(idea.id),
                            onSave: _saveIdea,
                            onSignIn: widget.onOpenProfile,
                            onOpen: () => _openDestination(
                              DestinationRequest.text(
                                idea.name,
                                '${idea.name}, ${idea.country}',
                              ),
                            ),
                          );
                        },
                      ),

                    SizedBox(height: height * 0.03),
                  ],
                ),
              ),
            ),
          ),

          SlideFadeTransition(
            visible: _showFlightSearch,
            onClose: () {
              setState(() {
                _showFlightSearch = false;
                widget.toggleBottomBar(true);
              });
            },
            child: FlightSearchScreen(
              onClose: () {
                setState(() {
                  _showFlightSearch = false;
                  widget.toggleBottomBar(true);
                });
              },
            ),
          ),

          SlideFadeTransition(
            visible: _showHotelsSearch,
            onClose: () {
              setState(() {
                _showHotelsSearch = false;
                widget.toggleBottomBar(true);
              });
            },
            child: HotelsSearchScreen(
              onClose: () {
                setState(() {
                  _showHotelsSearch = false;
                  widget.toggleBottomBar(true);
                });
              },
            ),
          ),

          SlideFadeTransition(
            visible: _showRentalSearch,
            onClose: () {
              setState(() {
                _showRentalSearch = false;
                widget.toggleBottomBar(true);
              });
            },
            child: RentalsSearchScreen(
              onClose: () {
                setState(() {
                  _showRentalSearch = false;
                  widget.toggleBottomBar(true);
                });
              },
            ),
          ),

          SlideFadeTransition(
            visible: _showDestinationInfo,
            onClose: _closeDestination,
            child: _destination == null
                ? const SizedBox.shrink()
                : DestinationInfoScreen(
                    request: _destination!,
                    onClose: _closeDestination,
                  ),
          ),
        ],
      ),
    );
  }
}

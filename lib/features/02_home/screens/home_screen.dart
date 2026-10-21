import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/features/02_home/widgets/category_button.dart';
import 'package:app_frontend/features/02_home/widgets/stacked_card_carousel.dart';
import 'package:app_frontend/features/03_flights/screens/flight_search_screen.dart';
import 'package:app_frontend/features/04_hotels/screens/hotels_search_screen.dart';
import 'package:app_frontend/features/05_rentals/screens/rentals_search_screen.dart';
import 'package:app_frontend/features/06_destinationInfo/screens/destination_info_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final void Function(bool) toggleBottomBar;
  final UserModel? user;
  const HomeScreen({super.key, required this.toggleBottomBar, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _showFlightSearch = false;
  bool _showHotelsSearch = false;
  bool _showRentalSearch = false;
  bool _showDestinationInfo = false;
  String _searchedPlace = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

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
                    Container(
                      decoration: BoxDecoration(
                        color: ColorsUtil.secondaryLight,
                        borderRadius: BorderRadius.circular(width * 0.08),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.05,
                        vertical: height * 0.01,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.public,
                            color: ColorsUtil.whiteColor,
                            size: 32,
                          ),
                          SizedBox(width: width * 0.025),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              enableSuggestions: false,
                              keyboardAppearance: Brightness.dark,
                              style: const TextStyle(
                                color: ColorsUtil.whiteColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Where do you want to be?',
                                hintStyle: TextStyle(
                                  color: ColorsUtil.whiteColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                              ),
                              cursorColor: ColorsUtil.whiteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.015),

                    // Search Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus
                              ?.unfocus(); // Close keyboard

                          final place = _searchController.text.trim();
                          if (place.isNotEmpty) {
                            Analytics.track(const DestinationSearched());
                            setState(() {
                              _searchedPlace = place;
                              _showDestinationInfo = true;
                              widget.toggleBottomBar(false);
                            });
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

                    // Image Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(width * 0.04),
                      child: Image.asset(
                        'assets/images/home_image_01.png',
                        height: height * 0.23,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
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

                    // Horizontal Stacked Cards
                    StackedCardCarousel(),

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
            onClose: () {
              setState(() {
                _showDestinationInfo = false;
                _searchController.clear();
                _searchedPlace = '';
                FocusManager.instance.primaryFocus?.unfocus();
                widget.toggleBottomBar(true);
              });
            },
            child: DestinationInfoScreen(
              placeName: _searchedPlace,
              onClose: () {
                setState(() {
                  _showDestinationInfo = false;
                  _searchController.clear();
                  _searchedPlace = '';
                  FocusManager.instance.primaryFocus?.unfocus();
                  widget.toggleBottomBar(true);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

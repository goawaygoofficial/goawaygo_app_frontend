import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/features/04_hotels/screens/stay_results_screen.dart';
import 'package:app_frontend/features/04_hotels/utils/hotel_date_picker_util.dart';
import 'package:app_frontend/global_widgets/book/form_error.dart';
import 'package:app_frontend/global_widgets/book/suggest_field.dart';
import 'package:app_frontend/features/04_hotels/utils/hotel_form_controllers_utils.dart';
import 'package:app_frontend/global_widgets/search_input_field.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class HotelsSearchScreen extends StatefulWidget {
  final VoidCallback onClose;
  const HotelsSearchScreen({super.key, required this.onClose});

  @override
  State<HotelsSearchScreen> createState() => _HotelsSearchScreenState();
}

class _HotelsSearchScreenState extends State<HotelsSearchScreen> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController checkinController = TextEditingController();
  final TextEditingController checkoutController = TextEditingController();
  final TextEditingController roomsController = TextEditingController(
    text: '1',
  );
  final TextEditingController adultsController = TextEditingController(
    text: '2',
  );

  String? _error;

  static const _maxNights = 30;

  @override
  void dispose() {
    locationController.dispose();
    checkinController.dispose();
    checkoutController.dispose();
    roomsController.dispose();
    adultsController.dispose();
    super.dispose();
  }

  void _swapDates() {
    HotelFormControllersUtils.swapControllers(
      checkinController,
      checkoutController,
    );
  }

  /// What stops the search, or null when it can run.
  String? _problem() {
    final checkin = DateTime.tryParse(checkinController.text);
    final checkout = DateTime.tryParse(checkoutController.text);
    if (locationController.text.trim().length < 2) {
      return tr('Type where you want to stay.');
    }
    if (checkin == null || checkout == null) {
      return tr('Choose your check-in and check-out dates.');
    }
    final nights = checkout.difference(checkin).inDays;
    if (nights < 1) return tr('Check-out must be after check-in.');
    if (nights > _maxNights) {
      return tr('Choose a stay of up to {0} nights.', [_maxNights]);
    }
    final rooms = int.tryParse(roomsController.text) ?? 1;
    final guests = int.tryParse(adultsController.text) ?? 1;
    if (rooms > guests) return tr('Choose at least one guest per room.');
    return null;
  }

  void _search() {
    final problem = _problem();
    setState(() => _error = problem);
    if (problem != null) return;
    Analytics.track(BookSearched(TravelCategory.stays));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StayResultsScreen(
          search: StaySearch(
            place: locationController.text.trim(),
            checkin: checkinController.text,
            checkout: checkoutController.text,
            adults: (int.tryParse(adultsController.text) ?? 2).clamp(1, 30),
            rooms: (int.tryParse(roomsController.text) ?? 1).clamp(1, 8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Solid, like the website: the screen it opens over must not show through.
    return ColoredBox(
      color: ColorsUtil.primary,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight:
                  height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: height * 0.12,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: ColorsUtil.whiteColor,
                      ),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                SizedBox(height: height * 0.0075),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/stays.png',
                      height: height * 0.1,
                    ),
                    Text(
                      tr('Book Your Hotels'),
                      style: TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),

                // Location
                SuggestField<Place>(
                  icon: Icons.public,
                  hint: tr('Where? (city or area)'),
                  controller: locationController,
                  suggest: DiscoverService.suggestPlaces,
                  describe: (place) => Suggestion(
                    title: place.name,
                    context: place.context,
                    icon: place.type == 'country'
                        ? Icons.public
                        : Icons.location_on_outlined,
                  ),
                  onTextChanged: () => setState(() => _error = null),
                  onPick: (place) =>
                      setState(() => locationController.text = place.name),
                ),
                SizedBox(height: height * 0.005),

                // Dates
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SearchInputField(
                            icon: Icons.calendar_today,
                            hint: 'Check-in',
                            controller: checkinController,
                            onTap: () => HotelDatePickerUtils.selectDate(
                              context,
                              checkinController,
                              () => setState(() {}),
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.025),
                        Expanded(
                          child: SearchInputField(
                            icon: Icons.calendar_today,
                            hint: 'Check-out',
                            controller: checkoutController,
                            onTap: () => HotelDatePickerUtils.selectDate(
                              context,
                              checkoutController,
                              () => setState(() {}),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: height * 0.03,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorsUtil.primary,
                          borderRadius: BorderRadius.circular(width * 0.1),
                          border: Border.all(
                            color: ColorsUtil.whiteColor.withValues(alpha: 0.3),
                            width: width * 0.003,
                          ),
                        ),
                        padding: EdgeInsets.all(width * 0.015),
                        child: InkWell(
                          onTap: _swapDates,
                          borderRadius: BorderRadius.circular(width * 0.1),
                          child: Icon(
                            Icons.swap_horiz,
                            color: ColorsUtil.whiteColor,
                            size: height * 0.03,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.005),

                Row(
                  children: [
                    Expanded(
                      child: SearchInputField(
                        icon: Icons.hotel_rounded,
                        caption: tr('Rooms'),
                        min: 1,
                        controller: roomsController,
                        isCounter: true,
                      ),
                    ),
                    SizedBox(width: width * 0.035),
                    Expanded(
                      child: SearchInputField(
                        icon: Icons.person,
                        caption: tr('Guests'),
                        min: 1,
                        controller: adultsController,
                        isCounter: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.025),
                if (_error != null) FormError(_error!),

                // Search button
                Center(
                  child: ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsUtil.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.1,
                        vertical: height * 0.02,
                      ),
                    ),
                    child: Text(
                      tr('Search'),
                      style: TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/book/book_service.dart';
import 'package:app_frontend/features/05_rentals/screens/rental_results_screen.dart';
import 'package:app_frontend/features/05_rentals/utils/rentals_date_picker_util.dart';
import 'package:app_frontend/features/05_rentals/utils/rentals_form_controllers_utils.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/book/form_error.dart';
import 'package:app_frontend/global_widgets/book/suggest_field.dart';
import 'package:app_frontend/global_widgets/search_input_field.dart';
import 'package:app_frontend/global_widgets/swap_button.dart';
import 'package:flutter/material.dart';

/// Rent a car: where and when. Partners compare every rental company there (car type, drop-off elsewhere and
/// driver age are chosen on the partner's site).
class RentalsSearchScreen extends StatefulWidget {
  final VoidCallback onClose;
  const RentalsSearchScreen({super.key, required this.onClose});

  @override
  State<RentalsSearchScreen> createState() => _RentalsSearchScreenState();
}

class _RentalsSearchScreenState extends State<RentalsSearchScreen> {
  static const _maxDays = 30;

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController pickupDateController = TextEditingController();
  final TextEditingController dropOffDateController = TextEditingController();

  /// The picked suggestion (null until one is picked, and again when the text is edited).
  Airport? _pickup;
  String? _error;

  @override
  void dispose() {
    pickupController.dispose();
    pickupDateController.dispose();
    dropOffDateController.dispose();
    super.dispose();
  }

  void _swapDates() {
    RentalsFormControllersUtils.swapControllers(
      pickupDateController,
      dropOffDateController,
    );
  }

  /// What stops the search, or null when it can run.
  String? _problem() {
    final pickup = DateTime.tryParse(pickupDateController.text);
    final dropOff = DateTime.tryParse(dropOffDateController.text);
    if (pickupController.text.trim().length < 2) {
      return tr('Type where you pick up the car.');
    }
    if (pickup == null || dropOff == null) {
      return tr('Choose your pick-up and drop-off dates.');
    }
    final days = dropOff.difference(pickup).inDays;
    if (days < 1) return tr('Drop-off must be after pick-up.');
    if (days > _maxDays) {
      return tr('Choose a rental of up to {0} days.', [_maxDays]);
    }
    return null;
  }

  void _search() {
    final problem = _problem();
    setState(() => _error = problem);
    if (problem != null) return;
    Analytics.track(BookSearched(TravelCategory.rentals));
    final airport = _pickup != null && _pickup!.isAirport ? _pickup : null;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RentalResultsScreen(
          search: CarSearch(
            place: airport != null
                ? (airport.city.isNotEmpty ? airport.city : airport.name)
                : pickupController.text.trim(),
            airport: airport?.code,
            pickup: pickupDateController.text,
            dropoff: dropOffDateController.text,
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
                      tooltip: tr('Back'),
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
                      'assets/images/rentals.png',
                      height: height * 0.1,
                    ),
                    Text(
                      tr('Rent a Car'),
                      style: TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),

                // Pick-up: a city or an airport (an airport opens some partners right on it)
                SuggestField<Airport>(
                  icon: Icons.my_location_sharp,
                  hint: tr('Pick-up (city or airport)'),
                  controller: pickupController,
                  suggest: BookService.suggestAirports,
                  describe: (place) => Suggestion(
                    title: place.isAirport
                        ? '${place.name} (${place.code})'
                        : place.name,
                    context: place.isAirport
                        ? tr('Airport · {0}{1}', [
                            place.city.isEmpty ? '' : '${place.city}, ',
                            place.country,
                          ])
                        : tr('City · {0}', [place.country]),
                    icon: place.isAirport
                        ? Icons.flight
                        : Icons.location_on_outlined,
                  ),
                  onTextChanged: () => setState(() {
                    _pickup = null;
                    _error = null;
                  }),
                  onPick: (place) => setState(() {
                    _pickup = place;
                    pickupController.text = place.isAirport
                        ? '${place.name} (${place.code})'
                        : place.name;
                  }),
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
                            hint: 'Pick-up',
                            controller: pickupDateController,
                            onTap: () => RentalsDatePickerUtils.selectDate(
                              context,
                              pickupDateController,
                              () => setState(() => _error = null),
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.025),
                        Expanded(
                          child: SearchInputField(
                            icon: Icons.calendar_today,
                            hint: 'Drop-off',
                            controller: dropOffDateController,
                            onTap: () => RentalsDatePickerUtils.selectDate(
                              context,
                              dropOffDateController,
                              () => setState(() => _error = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: height * 0.03,
                      child: SwapButton(
                        icon: Icons.swap_horiz,
                        label: tr('Swap pick-up and drop-off dates'),
                        onPressed: _swapDates,
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

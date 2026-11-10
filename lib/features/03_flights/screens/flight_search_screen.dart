import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/book/book_service.dart';
import 'package:app_frontend/features/03_flights/screens/flight_results_screen.dart';
import 'package:app_frontend/features/03_flights/utils/flight_date_picker_util.dart';
import 'package:app_frontend/global_widgets/book/form_error.dart';
import 'package:app_frontend/global_widgets/book/suggest_field.dart';
import 'package:app_frontend/features/03_flights/utils/flight_form_controllers_utils.dart';
import 'package:app_frontend/global_widgets/search_input_field.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/swap_button.dart';
import 'package:flutter/material.dart';

class FlightSearchScreen extends StatefulWidget {
  final VoidCallback onClose;

  /// Filled in when opened from a trip plan: the destination and the trip's dates (`YYYY-MM-DD`).
  final Airport? to;
  final String? depart;
  final String? returnDate;

  const FlightSearchScreen({
    super.key,
    required this.onClose,
    this.to,
    this.depart,
    this.returnDate,
  });

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController departureController = TextEditingController();
  final TextEditingController returnController = TextEditingController();
  final TextEditingController adultsController = TextEditingController(
    text: '1',
  );

  bool isRoundTrip = true;

  /// The picked suggestions (null until one is picked, and again when the text is edited).
  Airport? _from;
  Airport? _to;
  String? _error;

  @override
  void initState() {
    super.initState();
    final to = widget.to;
    if (to != null) {
      _to = to;
      toController.text = to.label;
    }
    departureController.text = widget.depart ?? '';
    returnController.text = widget.returnDate ?? '';
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    departureController.dispose();
    returnController.dispose();
    adultsController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    FlightFormControllersUtils.swapControllers(fromController, toController);
    setState(() {
      final from = _from;
      _from = _to;
      _to = from;
    });
  }

  static Suggestion _describe(Airport airport) => Suggestion(
    title: '${airport.name} (${airport.code})',
    context: airport.isAirport
        ? '${airport.city.isEmpty ? '' : '${airport.city}, '}${airport.country}'
        : tr('All airports · {0}', [airport.country]),
    icon: airport.isAirport ? Icons.flight : Icons.location_on_outlined,
  );

  /// What stops the search, or null when it can run.
  String? _problem() {
    final depart = departureController.text;
    final back = returnController.text;
    if (_from == null) {
      return tr('Pick where you fly from from the suggestions.');
    }
    if (_to == null) return tr('Pick where you fly to from the suggestions.');
    if (_from!.code == _to!.code) return tr('Pick a different destination.');
    if (depart.isEmpty) return tr('Choose a departure date.');
    if (isRoundTrip && back.isEmpty) return tr('Choose a return date.');
    if (isRoundTrip && back.compareTo(depart) < 0) {
      return tr('The return date must be on or after the departure date.');
    }
    return null;
  }

  void _search() {
    final problem = _problem();
    setState(() => _error = problem);
    if (problem != null) return;
    Analytics.track(BookSearched(TravelCategory.flights));
    final passengers = (int.tryParse(adultsController.text) ?? 1).clamp(1, 9);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlightResultsScreen(
          search: FlightSearch(
            from: _from!,
            to: _to!,
            depart: departureController.text,
            returnDate: isRoundTrip ? returnController.text : null,
            adults: passengers,
          ),
        ),
      ),
    );
  }

  void _swapDates() {
    FlightFormControllersUtils.swapControllers(
      departureController,
      returnController,
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
                      'assets/images/flights.png',
                      height: height * 0.1,
                    ),
                    // Wraps instead of overflowing with large text (WCAG 1.4.4).
                    Flexible(
                      child: Text(
                        tr('Book Your Flights'),
                        style: TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.01),

                //Locations
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        SuggestField<Airport>(
                          icon: Icons.location_on_outlined,
                          hint: tr('From (city or airport)'),
                          controller: fromController,
                          suggest: BookService.suggestAirports,
                          describe: _describe,
                          onTextChanged: () => setState(() {
                            _from = null;
                            _error = null;
                          }),
                          onPick: (airport) => setState(() {
                            _from = airport;
                            fromController.text = airport.label;
                          }),
                        ),
                        SuggestField<Airport>(
                          icon: Icons.public,
                          hint: tr('To (city or airport)'),
                          controller: toController,
                          suggest: BookService.suggestAirports,
                          describe: _describe,
                          onTextChanged: () => setState(() {
                            _to = null;
                            _error = null;
                          }),
                          onPick: (airport) => setState(() {
                            _to = airport;
                            toController.text = airport.label;
                          }),
                        ),
                      ],
                    ),
                    Positioned(
                      top: height * 0.085,
                      child: SwapButton(
                        icon: Icons.swap_vert,
                        label: tr('Swap origin and destination'),
                        onPressed: _swapLocations,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.025),

                // Trip Type Toggle (wraps with large text)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(tr('One Way')),
                      selected: !isRoundTrip,
                      onSelected: (selected) {
                        setState(() {
                          isRoundTrip = !selected;
                          if (!isRoundTrip) {
                            returnController.clear(); // Clear return date
                          }
                        });
                      },
                      selectedColor: ColorsUtil.secondaryLight,
                      backgroundColor: ColorsUtil.field,
                      labelStyle: TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ChoiceChip(
                      label: Text(tr('Round Trip')),
                      selected: isRoundTrip,
                      onSelected: (selected) {
                        setState(() {
                          isRoundTrip = selected;
                        });
                      },
                      selectedColor: ColorsUtil.secondaryLight,
                      backgroundColor: ColorsUtil.field,
                      labelStyle: TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                            hint: tr('Departure'),
                            controller: departureController,
                            onTap: () => FlightDatePickerUtils.selectDate(
                              context,
                              departureController,
                              () => setState(() {}),
                            ),
                          ),
                        ),
                        if (isRoundTrip) ...[
                          SizedBox(width: width * 0.025),
                          Expanded(
                            child: SearchInputField(
                              icon: Icons.calendar_today,
                              hint: tr('Return'),
                              controller: returnController,
                              onTap: () => FlightDatePickerUtils.selectDate(
                                context,
                                returnController,
                                () => setState(() {}),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isRoundTrip)
                      Positioned(
                        top: height * 0.03,
                        child: SwapButton(
                          icon: Icons.swap_horiz,
                          label: tr('Swap departure and return dates'),
                          onPressed: _swapDates,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: height * 0.005),

                // Passengers (prices are per passenger)
                SearchInputField(
                  icon: Icons.person,
                  caption: tr('Passengers'),
                  min: 1,
                  controller: adultsController,
                  isCounter: true,
                ),
                SizedBox(height: height * 0.015),
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

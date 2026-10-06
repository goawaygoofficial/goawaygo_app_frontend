// ignore_for_file: deprecated_member_use

import 'package:app_frontend/features/03_flights/utils/flight_date_picker_util.dart';
import 'package:app_frontend/features/03_flights/utils/flight_form_controllers_utils.dart';
import 'package:app_frontend/features/03_flights/widgets/flight_input_field.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class FlightSearchScreen extends StatefulWidget {
  final VoidCallback onClose;
  const FlightSearchScreen({super.key, required this.onClose});

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
  final TextEditingController childrenController = TextEditingController(
    text: '0',
  );

  bool isRoundTrip = true;

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    departureController.dispose();
    returnController.dispose();
    adultsController.dispose();
    childrenController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    FlightFormControllersUtils.swapControllers(fromController, toController);
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

    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight:
                height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          color: ColorsUtil.primary.withOpacity(0.95),
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', height: height * 0.12),
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
                    'assets/images/flights.png',
                    height: height * 0.1,
                  ),
                  const Text(
                    'Book Your Flights',
                    style: TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                      FlightInputField(
                        icon: Icons.location_on_outlined,
                        hint: 'From',
                        controller: fromController,
                      ),
                      FlightInputField(
                        icon: Icons.public,
                        hint: 'To',
                        controller: toController,
                      ),
                    ],
                  ),
                  Positioned(
                    top: height * 0.085,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorsUtil.primary,
                        borderRadius: BorderRadius.circular(width * 0.1),
                        border: Border.all(
                          color: ColorsUtil.whiteColor.withOpacity(0.3),
                          width: width * 0.003,
                        ),
                      ),
                      padding: EdgeInsets.all(width * 0.015),
                      child: InkWell(
                        onTap: _swapLocations,
                        borderRadius: BorderRadius.circular(width * 0.1),
                        child: Icon(
                          Icons.swap_vert,
                          color: ColorsUtil.whiteColor,
                          size: height * 0.035,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              // Trip Type Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text('One Way'),
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
                    backgroundColor: ColorsUtil.primaryLight,
                    labelStyle: TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 10),
                  ChoiceChip(
                    label: Text('Round Trip'),
                    selected: isRoundTrip,
                    onSelected: (selected) {
                      setState(() {
                        isRoundTrip = selected;
                      });
                    },
                    selectedColor: ColorsUtil.secondaryLight,
                    backgroundColor: ColorsUtil.primaryLight,
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
                        child: FlightInputField(
                          icon: Icons.calendar_today,
                          hint: 'Departure',
                          controller: departureController,
                          onTap:
                              () => FlightDatePickerUtils.selectDate(
                                context,
                                departureController,
                                () => setState(() {}),
                              ),
                        ),
                      ),
                      if (isRoundTrip) ...[
                        SizedBox(width: width * 0.025),
                        Expanded(
                          child: FlightInputField(
                            icon: Icons.calendar_today,
                            hint: 'Return',
                            controller: returnController,
                            onTap:
                                () => FlightDatePickerUtils.selectDate(
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorsUtil.primary,
                          borderRadius: BorderRadius.circular(width * 0.1),
                          border: Border.all(
                            color: ColorsUtil.whiteColor.withOpacity(0.3),
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

              // Passengers
              Row(
                children: [
                  Expanded(
                    child: FlightInputField(
                      icon: Icons.person,
                      controller: adultsController,
                      isCounter: true,
                    ),
                  ),
                  SizedBox(width: width * 0.035),
                  Expanded(
                    child: FlightInputField(
                      icon: Icons.child_care_sharp,
                      controller: childrenController,
                      isCounter: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              // Search button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement search functionality
                  },
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
            ],
          ),
        ),
      ),
    );
  }
}

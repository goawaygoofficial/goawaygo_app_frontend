// ignore_for_file: deprecated_member_use

import 'package:app_frontend/features/05_rentals/utils/rentals_date_picker_util.dart';
import 'package:app_frontend/features/05_rentals/utils/rentals_form_controllers_utils.dart';
import 'package:app_frontend/features/05_rentals/widgets/rentals_input_field.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class RentalsSearchScreen extends StatefulWidget {
  final VoidCallback onClose;
  const RentalsSearchScreen({super.key, required this.onClose});

  @override
  State<RentalsSearchScreen> createState() => _RentalsSearchScreenState();
}

class _RentalsSearchScreenState extends State<RentalsSearchScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropController = TextEditingController();
  final TextEditingController departureController = TextEditingController();
  final TextEditingController returnController = TextEditingController();
  final TextEditingController carTypeController = TextEditingController();

  bool isRoundTrip = true;

  @override
  void dispose() {
    pickupController.dispose();
    dropController.dispose();
    departureController.dispose();
    returnController.dispose();
    carTypeController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    RentalsFormControllersUtils.swapControllers(
      pickupController,
      dropController,
    );
  }

  void _swapDates() {
    RentalsFormControllersUtils.swapControllers(
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
                    'assets/images/rentals.png',
                    height: height * 0.1,
                  ),
                  const Text(
                    'Rent a Car',
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
                      RentalsInputField(
                        icon: Icons.my_location_sharp,
                        hint: 'Pickup',
                        controller: pickupController,
                      ),
                      RentalsInputField(
                        icon: Icons.location_on_sharp,
                        hint: 'Drop-off',
                        controller: dropController,
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
              // Dates
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RentalsInputField(
                          icon: Icons.calendar_today,
                          hint: 'Departure',
                          controller: departureController,
                          isTapEnabled: true,
                          onTap:
                              () => RentalsDatePickerUtils.selectDate(
                                context,
                                departureController,
                                () => setState(() {}),
                              ),
                        ),
                      ),
                      if (isRoundTrip) ...[
                        SizedBox(width: width * 0.025),
                        Expanded(
                          child: RentalsInputField(
                            icon: Icons.calendar_today,
                            hint: 'Return',
                            controller: returnController,
                            isTapEnabled: true,
                            onTap:
                                () => RentalsDatePickerUtils.selectDate(
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

              // Car type
              RentalsInputField(
                icon: Icons.directions_car,
                controller: carTypeController,
                dropdownItems: [
                  'Sedan',
                  'SUV',
                  'Hatchback',
                  'Convertible',
                  'Van',
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

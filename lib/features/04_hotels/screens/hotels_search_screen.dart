import 'package:app_frontend/features/04_hotels/utils/hotel_date_picker_util.dart';
import 'package:app_frontend/features/04_hotels/utils/hotel_form_controllers_utils.dart';
import 'package:app_frontend/features/04_hotels/widgets/hotels_input_field.dart';
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
    text: '1',
  );

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
          // ignore: deprecated_member_use
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
                  Image.asset('assets/images/stays.png', height: height * 0.1),
                  const Text(
                    'Book Your Hotels',
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
              HotelInputField(
                icon: Icons.public,
                hint: 'Where?',
                controller: locationController,
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
                        child: HotelInputField(
                          icon: Icons.calendar_today,
                          hint: 'Check-in',
                          controller: checkinController,
                          onTap:
                              () => HotelDatePickerUtils.selectDate(
                                context,
                                checkinController,
                                () => setState(() {}),
                              ),
                        ),
                      ),
                      SizedBox(width: width * 0.025),
                      Expanded(
                        child: HotelInputField(
                          icon: Icons.calendar_today,
                          hint: 'Check-out',
                          controller: checkoutController,
                          onTap:
                              () => HotelDatePickerUtils.selectDate(
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
                          // ignore: deprecated_member_use
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

              Row(
                children: [
                  Expanded(
                    child: HotelInputField(
                      icon: Icons.hotel_rounded,
                      controller: roomsController,
                      isCounter: true,
                    ),
                  ),
                  SizedBox(width: width * 0.035),
                  Expanded(
                    child: HotelInputField(
                      icon: Icons.person,
                      controller: adultsController,
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

import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// The My Trips tab. There is no bookings API yet, so it is an honest empty state (same as the website's),
/// with a way to start planning.
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key, required this.onPlanTrip});

  /// Opens Home, where the searches start.
  final VoidCallback onPlanTrip;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: height * 0.12,
                ),
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
              const Text(
                'NO TRIPS YET',
                style: TextStyle(
                  color: ColorsUtil.whiteColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: height * 0.015),
              SizedBox(
                width: width * 0.7,
                child: Text(
                  'Trips you book with GoAwayGo will show up here. Start by finding a flight, a stay or a car.',
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
                onPressed: onPlanTrip,
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
                child: const Text(
                  'Plan a trip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

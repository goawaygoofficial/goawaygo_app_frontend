import 'package:app_frontend/features/06_destinationInfo/utils/info_items.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class DestinationInfoScreen extends StatefulWidget {
  final String placeName;
  final VoidCallback onClose;

  const DestinationInfoScreen({
    super.key,
    required this.placeName,
    required this.onClose,
  });

  @override
  State<DestinationInfoScreen> createState() => _DestinationInfoScreenState();
}

class _DestinationInfoScreenState extends State<DestinationInfoScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final infoItems = InfoItems(widget.placeName).infoItems;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(color: ColorsUtil.primary),
          child: Column(
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

              // Header
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(width * 0.05)),
                child: Image.asset(
                  'assets/images/home_image_01.png',
                  width: double.infinity,
                  height: height * 0.28,
                  fit: BoxFit.cover,
                ),
              ),

              SizedBox(height: height * 0.025),

              // Info List
              Expanded(
                child: ListView.builder(
                  itemCount: infoItems.length,
                  itemBuilder: (context, index) {
                    final item = infoItems[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: height * 0.02),
                      constraints: BoxConstraints(minHeight: height * 0.1),
                      decoration: BoxDecoration(
                        color: ColorsUtil.secondary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: width * 0.05,
                            vertical: height * 0.015,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: ColorsUtil.primary,
                            radius: width * 0.06,
                            child: Center(
                              child: Icon(
                                item['icon'] as IconData,
                                color: ColorsUtil.whiteColor,
                                size: width * 0.075,
                              ),
                            ),
                          ),
                          title: Text(
                            item['title'] as String,
                            style: const TextStyle(
                              color: ColorsUtil.whiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            item['subtitle'] as String,
                            style: const TextStyle(
                              color: ColorsUtil.whiteLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () {
                            // TODO: Navigate to detail screen or expand info
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

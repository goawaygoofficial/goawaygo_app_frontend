import 'package:flutter/material.dart';
import 'package:app_frontend/global_utils/colors.dart';

class WanderbookSearchBar extends StatefulWidget {
  final TextEditingController controller;

  const WanderbookSearchBar({super.key, required this.controller});

  @override
  State<WanderbookSearchBar> createState() => _WanderbookSearchBarState();
}

class _WanderbookSearchBarState extends State<WanderbookSearchBar> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.02,
        vertical: height * 0.01,
      ),
      color: ColorsUtil.primary,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: height * 0.06,
              decoration: BoxDecoration(
                gradient: ColorsUtil.orangeWhiteGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Row(
                children: [
                  Icon(Icons.search, color: ColorsUtil.secondaryDark, size: 28),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      decoration: const InputDecoration(
                        hintText: "Destination",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: ColorsUtil.secondaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

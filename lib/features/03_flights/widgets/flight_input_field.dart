import 'package:app_frontend/features/03_flights/utils/flight_form_controllers_utils.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class FlightInputField extends StatefulWidget {
  final IconData icon;
  final String? hint;
  final TextEditingController? controller;
  final bool isCounter;
  final VoidCallback? onTap;

  const FlightInputField({
    super.key,
    required this.icon,
    this.hint,
    this.controller,
    this.isCounter = false,
    this.onTap,
  });

  @override
  State<FlightInputField> createState() => _FlightInputFieldState();
}

class _FlightInputFieldState extends State<FlightInputField> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(vertical: height * 0.01),
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.0165,
      ),
      decoration: BoxDecoration(
        color: ColorsUtil.primaryLight,
        borderRadius: BorderRadius.circular(height * 0.04),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: ColorsUtil.whiteColor, size: height * 0.04),
          SizedBox(width: width * 0.04),
          if (!widget.isCounter)
            Expanded(
              child: widget.controller == null
                  ? Text(
                      widget.hint!,
                      style: const TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : widget.onTap != null
                  ? GestureDetector(
                      onTap: widget.onTap,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: widget.controller,
                          enableSuggestions: false,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: ColorsUtil.whiteColor,
                          style: const TextStyle(color: ColorsUtil.whiteColor),
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            hintStyle: const TextStyle(
                              color: ColorsUtil.whiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    )
                  : TextField(
                      controller: widget.controller,
                      enableSuggestions: false,
                      keyboardAppearance: Brightness.dark,
                      cursorColor: ColorsUtil.whiteColor,
                      style: const TextStyle(color: ColorsUtil.whiteColor),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: const TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  InkWell(
                    onTap: () => FlightFormControllersUtils.decrementController(
                      widget.controller,
                    ),
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      enableSuggestions: false,
                      keyboardAppearance: Brightness.dark,
                      cursorColor: ColorsUtil.whiteColor,
                      style: const TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  InkWell(
                    onTap: () => FlightFormControllersUtils.incrementController(
                      widget.controller,
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

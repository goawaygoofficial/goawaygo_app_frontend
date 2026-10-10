import 'package:app_frontend/features/05_rentals/utils/rentals_form_controllers_utils.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

class RentalsInputField extends StatefulWidget {
  final IconData icon;
  final String? hint;
  final TextEditingController? controller;
  final bool isCounter;
  final bool isTapEnabled;
  final VoidCallback? onTap;
  final List<String>? dropdownItems;

  const RentalsInputField({
    super.key,
    required this.icon,
    this.hint,
    this.controller,
    this.isCounter = false,
    this.onTap,
    this.dropdownItems,
    this.isTapEnabled = false,
  });

  @override
  State<RentalsInputField> createState() => _RentalsInputFieldState();
}

class _RentalsInputFieldState extends State<RentalsInputField> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();

    if (widget.dropdownItems != null && widget.dropdownItems!.isNotEmpty) {
      if (widget.controller != null &&
          widget.dropdownItems!.contains(widget.controller!.text)) {
        selectedValue = widget.controller!.text;
      } else {
        selectedValue = widget.dropdownItems!.first;
        widget.controller?.text = selectedValue!;
      }
    }
  }

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
              child: widget.dropdownItems != null
                  ? DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedValue,
                        dropdownColor: ColorsUtil.primaryLight,
                        iconEnabledColor: ColorsUtil.whiteColor,
                        style: const TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        items: widget.dropdownItems!.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedValue = newValue;
                            if (widget.controller != null && newValue != null) {
                              widget.controller!.text = newValue;
                            }
                          });
                        },
                      ),
                    )
                  : widget.controller == null
                  ? Text(
                      widget.hint!,
                      style: const TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : widget.isTapEnabled == false
                  ? TextField(
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
                    )
                  : GestureDetector(
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
                    ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  InkWell(
                    onTap: () =>
                        RentalsFormControllersUtils.decrementController(
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
                    onTap: () =>
                        RentalsFormControllersUtils.incrementController(
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

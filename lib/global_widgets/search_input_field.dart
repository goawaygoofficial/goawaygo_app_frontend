import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// The pill-shaped field used by every search form (Flights, Stays, Rentals), like the website's `FieldShell`.
///
/// One of four kinds, chosen by the arguments:
/// - text: [controller] + [hint];
/// - tap-only (dates): [controller] + [hint] + [onTap], which opens a picker instead of the keyboard;
/// - counter: [isCounter], with − / + limited to [min];
/// - dropdown: [dropdownItems], showing [hint] until something is picked.
///
/// [caption] adds a small uppercase label above the value (counters and dropdowns, where the value alone
/// doesn't say what it is).
class SearchInputField extends StatefulWidget {
  const SearchInputField({
    super.key,
    required this.icon,
    this.hint,
    this.caption,
    this.controller,
    this.isCounter = false,
    this.min = 0,
    this.onTap,
    this.dropdownItems,
  });

  final IconData icon;
  final String? hint;
  final String? caption;
  final TextEditingController? controller;
  final bool isCounter;
  final int min;
  final VoidCallback? onTap;
  final List<String>? dropdownItems;

  @override
  State<SearchInputField> createState() => _SearchInputFieldState();
}

class _SearchInputFieldState extends State<SearchInputField> {
  static const _valueStyle = TextStyle(
    color: ColorsUtil.whiteColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  String? _selected;

  @override
  void initState() {
    super.initState();
    final current = widget.controller?.text;
    if (widget.dropdownItems?.contains(current) ?? false) _selected = current;
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  // Counters redraw their − button state when the value changes.
  void _onControllerChanged() {
    if (mounted && widget.isCounter) setState(() {});
  }

  int get _count => int.tryParse(widget.controller?.text ?? '') ?? widget.min;

  void _step(int delta) {
    final next = _count + delta;
    if (next < widget.min) return;
    widget.controller?.text = next.toString();
  }

  InputDecoration _decoration() => InputDecoration(
    hintText: widget.hint,
    hintStyle: _valueStyle,
    border: InputBorder.none,
    isDense: widget.caption != null,
  );

  Widget _textField({bool readOnly = false}) => TextField(
    controller: widget.controller,
    readOnly: readOnly,
    enableSuggestions: false,
    keyboardAppearance: Brightness.dark,
    cursorColor: ColorsUtil.whiteColor,
    style: _valueStyle,
    decoration: _decoration(),
  );

  Widget _buildValue(double width) {
    if (widget.isCounter) {
      final canDecrement = _count > widget.min;
      return Row(
        children: [
          IconButton(
            tooltip: 'Decrease',
            visualDensity: VisualDensity.compact,
            onPressed: canDecrement ? () => _step(-1) : null,
            icon: Icon(
              Icons.remove,
              color: ColorsUtil.whiteColor.withValues(
                alpha: canDecrement ? 1 : 0.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$_count',
              textAlign: TextAlign.center,
              style: _valueStyle,
            ),
          ),
          IconButton(
            tooltip: 'Increase',
            visualDensity: VisualDensity.compact,
            onPressed: () => _step(1),
            icon: const Icon(Icons.add, color: ColorsUtil.whiteColor),
          ),
        ],
      );
    }
    if (widget.dropdownItems != null) {
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selected,
          isExpanded: true,
          isDense: true,
          hint: Text(widget.hint ?? '', style: _valueStyle),
          dropdownColor: ColorsUtil.primaryLight,
          iconEnabledColor: ColorsUtil.whiteColor,
          style: _valueStyle,
          items: [
            for (final item in widget.dropdownItems!)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) {
            setState(() => _selected = value);
            if (value != null) widget.controller?.text = value;
          },
        ),
      );
    }
    if (widget.controller == null) {
      return Text(widget.hint ?? '', style: _valueStyle);
    }
    if (widget.onTap != null) {
      // Dates: a picker opens instead of the keyboard.
      return GestureDetector(
        onTap: widget.onTap,
        child: AbsorbPointer(child: _textField(readOnly: true)),
      );
    }
    return _textField();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final value = _buildValue(width);

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
          SizedBox(width: width * 0.03),
          Expanded(
            child: widget.caption == null
                ? value
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.caption!.toUpperCase(),
                        style: TextStyle(
                          color: ColorsUtil.whiteColor.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),
                      value,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

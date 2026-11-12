import 'dart:async';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// How one suggestion is shown.
class Suggestion {
  const Suggestion({
    required this.title,
    required this.context,
    required this.icon,
  });

  final String title;
  final String context;
  final IconData icon;
}

/// A search-form field (the pill of `SearchInputField`) that suggests real places while typing: airports and
/// cities, or destinations. Picking one fills the field; typing again clears the pick ([onTextChanged]), so the
/// form knows whether a suggestion was chosen. Like the website's `SuggestField`.
class SuggestField<T> extends StatefulWidget {
  const SuggestField({
    super.key,
    required this.icon,
    required this.hint,
    required this.controller,
    required this.suggest,
    required this.describe,
    required this.onPick,
    this.onTextChanged,
  });

  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final Future<List<T>> Function(String text) suggest;
  final Suggestion Function(T item) describe;
  final void Function(T item) onPick;
  final VoidCallback? onTextChanged;

  @override
  State<SuggestField<T>> createState() => _SuggestFieldState<T>();
}

class _SuggestFieldState<T> extends State<SuggestField<T>> {
  static const _debounce = Duration(milliseconds: 250);
  static const _minChars = 2;
  static const _valueStyle = TextStyle(
    color: ColorsUtil.whiteColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  final _focus = FocusNode();
  Timer? _timer;
  List<T> _suggestions = [];

  /// The text the shown suggestions are for; answers for older text are ignored.
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onTextChanged?.call();
    _timer?.cancel();
    final query = value.trim();
    _query = query;
    if (query.length < _minChars) {
      setState(() => _suggestions = []);
      return;
    }
    _timer = Timer(_debounce, () async {
      try {
        final items = await widget.suggest(query);
        if (mounted && query == _query) setState(() => _suggestions = items);
      } on ApiException {
        // Suggestions are a help: without them the form says what is missing.
      }
    });
  }

  void _pick(T item) {
    _focus.unfocus();
    setState(() => _suggestions = []);
    widget.onPick(item);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final showList = _focus.hasFocus && _suggestions.isNotEmpty;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: height * 0.01),
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.0165,
          ),
          decoration: BoxDecoration(
            color: ColorsUtil.field,
            borderRadius: BorderRadius.circular(height * 0.04),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: ColorsUtil.whiteColor,
                size: height * 0.04,
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enableSuggestions: false,
                  autocorrect: false,
                  maxLength: 100,
                  keyboardAppearance: Brightness.dark,
                  onChanged: _onChanged,
                  cursorColor: ColorsUtil.whiteColor,
                  style: _valueStyle,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: _valueStyle,
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showList)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: ColorsUtil.whiteColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (final item in _suggestions)
                  Builder(
                    builder: (context) {
                      final shown = widget.describe(item);
                      return ListTile(
                        dense: true,
                        leading: Icon(shown.icon, color: ColorsUtil.secondary),
                        title: Text(
                          shown.title,
                          style: const TextStyle(
                            color: ColorsUtil.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: shown.context.isEmpty
                            ? null
                            : Text(
                                shown.context,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorsUtil.primary.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                              ),
                        onTap: () => _pick(item),
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

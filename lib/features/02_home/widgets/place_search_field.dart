import 'package:app_frontend/core/i18n/i18n.dart';

import 'dart:async';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// "Where do you want to be?" with real places suggested while typing (countries, regions, cities, landmarks).
/// Picking one opens exactly that place; Search without picking opens the best match for the text.
class PlaceSearchField extends StatefulWidget {
  const PlaceSearchField({
    super.key,
    required this.controller,
    required this.onPick,
    required this.onSearch,
  });

  final TextEditingController controller;
  final void Function(Place place) onPick;
  final void Function(String text) onSearch;

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  static const _debounce = Duration(milliseconds: 250);
  static const _minChars = 2;

  final _focus = FocusNode();
  Timer? _timer;
  List<Place> _suggestions = const [];

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
    _timer?.cancel();
    final query = value.trim();
    _query = query;
    if (query.length < _minChars) {
      setState(() => _suggestions = const []);
      return;
    }
    _timer = Timer(_debounce, () async {
      try {
        final places = await DiscoverService.suggestPlaces(query);
        if (mounted && query == _query) setState(() => _suggestions = places);
      } on ApiException {
        // Suggestions are a help, not required: Search still works without them.
      }
    });
  }

  void _pick(Place place) {
    _focus.unfocus();
    setState(() => _suggestions = const []);
    widget.onPick(place);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showList = _focus.hasFocus && _suggestions.isNotEmpty;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: ColorsUtil.secondaryLight,
            borderRadius: BorderRadius.circular(width * 0.08),
          ),
          padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.public, color: ColorsUtil.whiteColor, size: 32),
              SizedBox(width: width * 0.025),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enableSuggestions: false,
                  autocorrect: false,
                  maxLength: 100,
                  textInputAction: TextInputAction.search,
                  keyboardAppearance: Brightness.dark,
                  onChanged: _onChanged,
                  onSubmitted: (text) {
                    setState(() => _suggestions = const []);
                    widget.onSearch(text.trim());
                  },
                  style: const TextStyle(
                    color: ColorsUtil.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: tr('Where do you want to be?'),
                    hintStyle: TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  cursorColor: ColorsUtil.whiteColor,
                ),
              ),
            ],
          ),
        ),
        if (showList)
          Container(
            margin: const EdgeInsets.only(top: 6),
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
                for (final place in _suggestions)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      place.type == 'country'
                          ? Icons.public
                          : Icons.location_on_outlined,
                      color: ColorsUtil.secondary,
                    ),
                    title: Text(
                      place.name,
                      style: const TextStyle(
                        color: ColorsUtil.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: place.context.isEmpty
                        ? null
                        : Text(
                            place.context,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorsUtil.primary.withValues(alpha: 0.75),
                            ),
                          ),
                    onTap: () => _pick(place),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

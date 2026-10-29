import 'dart:async';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_models.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// The post's place tag: place, state and country (names only). Filled in from the photo's location when it has
/// one; the user can search for another place, type it, or remove it.
class PlaceFields extends StatefulWidget {
  const PlaceFields({
    super.key,
    required this.value,
    required this.onChanged,
    this.fromPhoto = false,
  });

  final PlaceTag? value;
  final ValueChanged<PlaceTag?> onChanged;
  final bool fromPhoto;

  @override
  State<PlaceFields> createState() => _PlaceFieldsState();
}

class _PlaceFieldsState extends State<PlaceFields> {
  final _search = TextEditingController();
  late final _name = TextEditingController(text: widget.value?.name ?? '');
  late final _region = TextEditingController(text: widget.value?.region ?? '');
  late final _country = TextEditingController(
    text: widget.value?.country ?? '',
  );
  Timer? _timer;
  List<Place> _found = const [];

  @override
  void didUpdateWidget(PlaceFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A place set from outside (the photo's location): show it in the fields.
    final value = widget.value;
    if (value != null && value.label != _current?.label) _fill(value);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in [_search, _name, _region, _country]) {
      controller.dispose();
    }
    super.dispose();
  }

  PlaceTag? get _current {
    final name = _name.text.trim();
    if (name.isEmpty &&
        _region.text.trim().isEmpty &&
        _country.text.trim().isEmpty) {
      return null;
    }
    return PlaceTag(
      name: name,
      region: _region.text.trim(),
      country: _country.text.trim(),
    );
  }

  void _fill(PlaceTag? place) {
    _name.text = place?.name ?? '';
    _region.text = place?.region ?? '';
    _country.text = place?.country ?? '';
  }

  void _onSearch(String text) {
    _timer?.cancel();
    final query = text.trim();
    if (query.length < 2) {
      setState(() => _found = const []);
      return;
    }
    _timer = Timer(const Duration(milliseconds: 250), () async {
      try {
        final places = await DiscoverService.suggestPlaces(query);
        if (mounted && _search.text.trim() == query) {
          setState(() => _found = places);
        }
      } on ApiException {
        // Typing the names by hand still works.
      }
    });
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Colors.white.withValues(alpha: 0.75));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Place',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        if (widget.fromPhoto && widget.value != null)
          Text(
            "From your photo's location. Change it if it isn't right.",
            style: muted,
          ),
        const SizedBox(height: 6),
        TextField(
          controller: _search,
          maxLength: 100,
          decoration: _decoration('Find a place').copyWith(counterText: ''),
          onChanged: _onSearch,
        ),
        if (_found.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (final place in _found)
                  ListTile(
                    dense: true,
                    title: Text(
                      place.label,
                      style: const TextStyle(color: ColorsUtil.primary),
                    ),
                    onTap: () {
                      final tag = PlaceTag(
                        name: place.name,
                        region: place.type == 'region' ? '' : place.region,
                        country: place.type == 'country' ? '' : place.country,
                      );
                      _fill(tag);
                      _search.clear();
                      setState(() => _found = const []);
                      widget.onChanged(tag);
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        for (final (controller, hint, max) in [
          (_name, 'Place', 200),
          (_region, 'State or region', 200),
          (_country, 'Country', 100),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TextField(
              controller: controller,
              maxLength: max,
              decoration: _decoration(hint).copyWith(counterText: ''),
              onChanged: (_) => widget.onChanged(_current),
            ),
          ),
        if (widget.value != null)
          TextButton(
            onPressed: () {
              _fill(null);
              widget.onChanged(null);
            },
            child: const Text(
              'Remove place',
              style: TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }
}

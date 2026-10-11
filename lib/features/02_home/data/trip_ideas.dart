import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// A card in Home's "Ideas for your next trip" carousel.
class TripIdea {
  const TripIdea({
    required this.title,
    required this.destination,
    required this.country,
    required this.tagline,
    required this.colors,
  });

  final String title;
  final String destination;
  final String country;
  final String tagline;

  /// Card gradient, top-left to bottom-right.
  final List<Color> colors;
}

// The website's card gradients (sunset, ember, coral, peach).
const _sunset = [ColorsUtil.secondaryLight, ColorsUtil.secondaryDark];
const _ember = [ColorsUtil.secondary, ColorsUtil.secondaryDark];
const _coral = [ColorsUtil.secondaryLighter, ColorsUtil.secondary];
const _peach = [ColorsUtil.secondaryLight, ColorsUtil.primaryLight];

/// PLACEHOLDER content, the same as the website's (`PLACEHOLDER_TRIP_IDEAS`). There is no trip-ideas
/// endpoint yet; replace with a service call when one exists.
const placeholderTripIdeas = [
  TripIdea(
    title: 'Island sunsets',
    destination: 'Santorini',
    country: 'Greece',
    tagline: 'Whitewashed villages and caldera views.',
    colors: _sunset,
  ),
  TripIdea(
    title: 'Temples & blossoms',
    destination: 'Kyoto',
    country: 'Japan',
    tagline: 'Spring walks through a thousand shrines.',
    colors: _ember,
  ),
  TripIdea(
    title: 'Souks and spice',
    destination: 'Marrakech',
    country: 'Morocco',
    tagline: 'Rooftop dinners above the medina.',
    colors: _coral,
  ),
  TripIdea(
    title: 'Northern lights',
    destination: 'Reykjavik',
    country: 'Iceland',
    tagline: 'Hot springs by day, aurora by night.',
    colors: _peach,
  ),
  TripIdea(
    title: 'Rice terraces',
    destination: 'Bali',
    country: 'Indonesia',
    tagline: 'Jungle retreats and surf at sunrise.',
    colors: _sunset,
  ),
];

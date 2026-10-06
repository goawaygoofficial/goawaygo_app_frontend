import 'package:flutter/material.dart';

class InfoItems {
  final String placeName;

  InfoItems(this.placeName);

  List<Map<String, dynamic>> get infoItems => [
    {
      'icon': Icons.language,
      'title': 'Quick Facts',
      'subtitle': 'A brief overview of $placeName.',
    },
    {
      'icon': Icons.gavel,
      'title': 'Visa & Travel Restrictions',
      'subtitle': 'Find out if you need a visa and what travel rules apply.',
    },
    {
      'icon': Icons.calendar_month,
      'title': 'Peak vs. Off-Peak Seasons',
      'subtitle': 'Learn about the best and least crowded times to visit.',
    },
    {
      'icon': Icons.place,
      'title': 'Must-Visit Attractions & Activities',
      'subtitle': 'Explore top landmarks, tours, and unique local experiences.',
    },
    {
      'icon': Icons.hotel,
      'title': 'Best Hotels and Resorts',
      'subtitle': 'Browse the best places to stay across different budgets.',
    },
    {
      'icon': Icons.restaurant,
      'title': 'Local Cuisine & Dining',
      'subtitle': 'Discover must-try dishes, restaurants, and street food.',
    },
    {
      'icon': Icons.directions_bus,
      'title': 'Local Transport Options',
      'subtitle': 'How to get around — from public transit to taxis and more.',
    },
    {
      'icon': Icons.health_and_safety,
      'title': 'Travel Insurance',
      'subtitle': 'Learn why and what kind of insurance you might need.',
    },
    {
      'icon': Icons.attach_money,
      'title': 'Communication & Currency',
      'subtitle': 'Stay connected and manage your money with ease.',
    },
  ];
}

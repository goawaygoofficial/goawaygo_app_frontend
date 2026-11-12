import 'package:flutter/material.dart';

/// How an info card is labelled on the page.
class CardMeta {
  const CardMeta(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

/// The nine info cards by their backend id, in page order (titles and subtitles decided for 4.1; the website's
/// `cardMeta.ts` has the same).
const cardMeta = <String, CardMeta>{
  'quickFacts': CardMeta(
    Icons.language,
    'Quick Facts',
    "Country, languages, currency, time zone and what it's known for",
  ),
  'visa': CardMeta(
    Icons.gavel,
    'Visa & Entry Rules',
    'Visa systems, passport validity and entry requirements',
  ),
  'seasons': CardMeta(
    Icons.calendar_month,
    'Best Time to Visit',
    'Peak, off-peak and shoulder months, weather and big events',
  ),
  'attractions': CardMeta(
    Icons.place,
    'Top Attractions',
    'Famous landmarks and experiences worth your time',
  ),
  'hotels': CardMeta(
    Icons.hotel,
    'Best Areas to Stay',
    'Neighbourhoods to book in, and who each one suits',
  ),
  'cuisine': CardMeta(
    Icons.restaurant,
    'Food & Dining',
    'Dishes to try and local dining customs',
  ),
  'transport': CardMeta(
    Icons.directions_bus,
    'Getting Around',
    'From the airport and the main ways to travel locally',
  ),
  'insurance': CardMeta(
    Icons.health_and_safety,
    'Travel Insurance',
    "Whether it's required, medical care and local risks",
  ),
  'currency': CardMeta(
    Icons.attach_money,
    'Money & Connectivity',
    'Currency, cards or cash, tipping, SIM/eSIM, plugs and emergency number',
  ),
};

import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// The Flights / Stays / Car rentals results screen (the founder's design): logo and back, a title with its icon,
/// what was searched, the dates and travellers, the result cards, an optional floating pill and the commission
/// disclosure. Like the website's `ResultsLayout`.
class ResultsLayout extends StatelessWidget {
  const ResultsLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.heading,
    required this.dates,
    this.travellers,
    required this.note,
    this.floating,
    required this.children,
  });

  final IconData icon;
  final String title;

  /// "New Delhi to Mumbai", "Jaipur"
  final String heading;
  final String dates;

  /// "1 passenger", "2 guests · 1 room"
  final String? travellers;

  /// How to read the results ("Recent prices travellers found · they may change until you book").
  final String note;

  /// A pill floating at the bottom ("See all flights").
  final Widget? floating;
  final List<Widget> children;

  static const disclosure =
      "GoAwayGo may earn a commission when you book through these links. You pay the partner's price; "
      'bookings, payments and changes are handled by the partner.';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final muted = ColorsUtil.textMuted;

    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                width * 0.04,
                width * 0.04,
                width * 0.04,
                height * 0.12,
              ),
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: height * 0.1),
                    const Spacer(),
                    IconButton(
                      tooltip: tr('Back'),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: ColorsUtil.whiteColor,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: ColorsUtil.whiteColor, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ColorsUtil.whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                DefaultTextStyle(
                  style: const TextStyle(
                    color: ColorsUtil.textMuted,
                    fontSize: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: ColorsUtil.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Flexible(child: Text(dates)),
                      const Spacer(),
                      if (travellers != null) ...[
                        const Icon(
                          Icons.person,
                          color: ColorsUtil.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(travellers!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: child,
                  ),
                const SizedBox(height: 8),
                Text(
                  tr(disclosure),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
            if (floating != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: height * 0.025,
                child: Center(child: floating),
              ),
          ],
        ),
      ),
    );
  }
}

/// The founder's floating "More Option" pill: white fading into orange.
class FloatingPill extends StatelessWidget {
  const FloatingPill({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: ColorsUtil.orangeWhiteGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          // At least 48 high, Android's tap target (WCAG 2.5.8).
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Text(
              label,
              style: const TextStyle(
                color: ColorsUtil.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading, empty and error states inside a results screen.
class ResultsMessage extends StatelessWidget {
  const ResultsMessage({
    super.key,
    required this.title,
    this.text,
    this.onRetry,
    this.action,
  });

  final String title;
  final String? text;
  final VoidCallback? onRetry;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore,
            color: ColorsUtil.brandOrangeLight,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColorsUtil.whiteColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (text != null) ...[
            const SizedBox(height: 6),
            Text(
              text!,
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorsUtil.textMuted),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FloatingPill(label: tr('Try again'), onPressed: onRetry!),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

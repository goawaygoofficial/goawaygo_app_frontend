import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/legal/legal_pages.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// Asks once (when the app opens) whether we may collect anonymous usage statistics. Closing the sheet without
/// choosing counts as no answer: it asks again next time, and nothing is collected meanwhile.
Future<void> askForAnalyticsConsentIfNeeded(BuildContext context) async {
  if (!Analytics.available || Analytics.consent.value != null) return;
  await showAnalyticsConsentSheet(context);
}

/// The consent sheet, also opened from "Privacy choices". "No thanks" and "Allow" are equally easy.
Future<void> showAnalyticsConsentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ColorsUtil.primary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _ConsentSheet(),
  );
}

class _ConsentSheet extends StatelessWidget {
  const _ConsentSheet();

  @override
  Widget build(BuildContext context) {
    final current = Analytics.consent.value;
    const text = TextStyle(
      color: ColorsUtil.whiteColor,
      fontSize: 14,
      height: 1.4,
    );

    Future<void> choose(AnalyticsConsent value) async {
      Navigator.of(context).pop();
      await Analytics.setConsent(value);
    }

    Widget choice(String label, AnalyticsConsent value) => Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsUtil.whiteColor,
          foregroundColor: ColorsUtil.secondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () => choose(value),
        child: Text(label),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Help us improve GoAwayGo?'),
              style: TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr(
                tr(
                  'With your permission we collect anonymous usage statistics (which screens and features are used) with PostHog. No ads, no tracking across other apps, and you can change your mind any time under "Privacy choices" in Profile.',
                ),
              ),
              style: text,
            ),
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => openLegalPage(context, LegalPage.privacy),
              child: Text(
                tr('Learn more'),
                style: TextStyle(
                  color: ColorsUtil.whiteColor,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: ColorsUtil.whiteColor,
                ),
              ),
            ),
            if (current != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Currently: ${current == AnalyticsConsent.granted ? 'allowed' : 'not allowed'}.',
                  style: text.copyWith(color: ColorsUtil.textMuted),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                choice('No thanks', AnalyticsConsent.denied),
                const SizedBox(width: 12),
                choice('Allow', AnalyticsConsent.granted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

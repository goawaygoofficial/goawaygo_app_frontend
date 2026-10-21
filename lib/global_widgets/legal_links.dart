import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/legal/legal_pages.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/analytics_consent_sheet.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// "Privacy Policy · Terms of Use · Delete my data · Privacy choices", at the bottom of the sign-in screen and
/// Profile (as on the website). "Privacy choices" reopens the analytics consent sheet.
class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
      fontSize: 13,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final page in LegalPage.values)
          TextButton(
            onPressed: () => openLegalPage(context, page),
            child: Text(page.title, style: style),
          ),
        if (Analytics.available)
          TextButton(
            onPressed: () => showAnalyticsConsentSheet(context),
            child: Text('Privacy choices', style: style),
          ),
      ],
    );
  }
}

/// Shown where an account is created (the sign-in panel and Register), as on the website.
class SignUpNotice extends StatefulWidget {
  const SignUpNotice({super.key});

  @override
  State<SignUpNotice> createState() => _SignUpNoticeState();
}

class _SignUpNoticeState extends State<SignUpNotice> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => openLegalPage(context, LegalPage.terms);
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => openLegalPage(context, LegalPage.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const link = TextStyle(
      color: ColorsUtil.whiteColor,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
      decorationColor: ColorsUtil.whiteColor,
    );
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
          fontSize: 13,
          height: 1.4,
        ),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(text: 'Terms of Use', style: link, recognizer: _terms),
          const TextSpan(text: ' and confirm you have read our '),
          TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
          const TextSpan(text: '. You must be 18 or older.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

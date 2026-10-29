import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

/// The website's legal pages. The app opens them in the browser, so there is one copy of each text (in
/// web_frontend/src/features/legal). Keep the paths in sync with the website's routes.
enum LegalPage {
  privacy('Privacy Policy', '/privacy'),
  terms('Terms of Use', '/terms'),
  deleteMyData('Delete my data', '/delete-my-data'),
  communityGuidelines('Community Guidelines', '/community-guidelines');

  const LegalPage(this.title, this.path);

  final String title;
  final String path;

  /// The page's address on [websiteUrl] (from `WEBSITE_URL` in the env file), or null if that isn't set.
  Uri? uri([String? websiteUrl]) {
    final base = (websiteUrl ?? dotenv.env['WEBSITE_URL'] ?? '')
        .trim()
        .replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return null;
    return Uri.parse('$base$path');
  }
}

/// Opens [page] in the browser; tells the user if that isn't possible.
Future<void> openLegalPage(BuildContext context, LegalPage page) async {
  final uri = page.uri();
  final opened =
      uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    await CustomDialogs.showErrorDialog(
      context: context,
      message: "Couldn't open the ${page.title}. Please visit goawaygo.com.",
    );
  }
}

import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/account/account_models.dart';
import 'package:app_frontend/core/account/account_service.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/discover/discover_service.dart';
import 'package:app_frontend/core/plans/plan_service.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart'
    show timeAgo;
import 'package:app_frontend/features/06_destinationInfo/screens/destination_info_screen.dart';
import 'package:app_frontend/features/10_plans/screens/plan_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Recently viewed (Me, 4.6): the places and trip plans the signed-in user opened, newest first. Places open their
/// destination page, your plans open here, and plans shared with you open on the website.
class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({super.key});

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  RecentlyViewed? _viewed;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _viewed = null;
      _error = null;
    });
    try {
      final viewed = await AccountService.recentlyViewed();
      if (mounted) setState(() => _viewed = viewed);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _clear() async {
    final sure = await CustomDialogs.showConfirmDialog(
      context: context,
      message: tr('Clear everything you viewed?'),
      confirmLabel: tr('Clear'),
    );
    if (!sure) return;
    try {
      await AccountService.clearRecentlyViewed();
      if (mounted) setState(() => _viewed = const RecentlyViewed([], []));
    } on ApiException catch (error) {
      if (mounted) {
        await CustomDialogs.showErrorDialog(
          context: context,
          message: error.message,
        );
      }
    }
  }

  void _openPlace(ViewedPlace viewed) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => DestinationInfoScreen(
          request: DestinationRequest.place(viewed.place),
          onClose: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  Future<void> _openPlan(ViewedPlan plan) async {
    if (plan.mine) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => PlanScreen(id: plan.id)));
      return;
    }
    final link = PlanService.sharedLink(plan.id);
    if (link != null) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final viewed = _viewed;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                  Image.asset(
                    'assets/icons/recently_viewed.png',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      tr('Recently Viewed'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ColorsUtil.whiteColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                _Panel(
                  text: _error!,
                  action: TextButton(
                    onPressed: _load,
                    child: Text(
                      tr('Try again'),
                      style: TextStyle(color: ColorsUtil.secondaryLighter),
                    ),
                  ),
                )
              else if (viewed == null)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorsUtil.whiteColor,
                    ),
                  ),
                )
              else if (viewed.isEmpty)
                _Panel(
                  title: tr('Nothing yet'),
                  text: tr(
                    tr(
                      'Places and trip plans you open show up here, newest first.',
                    ),
                  ),
                )
              else ...[
                if (viewed.places.isNotEmpty) ...[
                  _Heading(tr('Places')),
                  for (final place in viewed.places)
                    _Row(
                      side: place.place.name,
                      title: place.place.label,
                      meta: place.viewedAt == null
                          ? null
                          : timeAgo(place.viewedAt!),
                      onTap: () => _openPlace(place),
                    ),
                ],
                if (viewed.plans.isNotEmpty) ...[
                  _Heading(tr('Trip plans')),
                  for (final plan in viewed.plans)
                    _Row(
                      side: plan.placeName,
                      title: plan.title,
                      meta: [
                        plan.mine ? tr('Your plan') : tr('Shared with you'),
                        if (plan.viewedAt != null) timeAgo(plan.viewedAt!),
                      ].join(' · '),
                      onTap: () => _openPlan(plan),
                    ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorsUtil.whiteColor,
                      side: const BorderSide(color: Colors.white70),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(tr('Clear list')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: ColorsUtil.whiteColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Two-tone orange row, like Book's result cards: the place on the left, details on the right.
class _Row extends StatelessWidget {
  const _Row({
    required this.side,
    required this.title,
    this.meta,
    required this.onTap,
  });

  final String side, title;
  final String? meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: ColorsUtil.secondaryLight,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  color: ColorsUtil.secondary,
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    side,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ColorsUtil.whiteColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.text, this.title, this.action});

  final String text;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorsUtil.whiteColor.withValues(alpha: 0.85),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

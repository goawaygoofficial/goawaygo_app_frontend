import 'package:app_frontend/core/i18n/i18n.dart';

import 'dart:async';

import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/book/book_models.dart';
import 'package:app_frontend/core/plans/plan_models.dart';
import 'package:app_frontend/core/plans/plan_service.dart';
import 'package:app_frontend/features/03_flights/screens/flight_search_screen.dart';
import 'package:app_frontend/features/04_hotels/screens/stay_results_screen.dart';
import 'package:app_frontend/features/05_rentals/screens/rental_results_screen.dart';
import 'package:app_frontend/features/10_plans/widgets/plan_widgets.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A trip plan (the website's `PlanPage`): the days with their places, food and tips, the cost estimate and
/// booking shortcuts. Its owner can change a day, share it by link (opens on the website) and delete it.
/// Given [plan] (just made), it shows it at once; otherwise it loads [id].
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.id, this.plan});

  final String id;
  final Plan? plan;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late Plan? _plan = widget.plan;
  String? _error;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    if (_plan == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _notFound = false;
    });
    try {
      final plan = await PlanService.get(widget.id);
      if (mounted) setState(() => _plan = plan);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _notFound = error.statusCode == 404;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final plan = _plan;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
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
            if (_notFound)
              PlanPanel(
                children: [
                  Text(
                    tr('This plan isn\'t available'),
                    style: TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('It may have been deleted.'),
                    style: TextStyle(
                      color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              )
            else if (_error != null)
              PlanPanel(
                children: [
                  Text(
                    tr('Something went wrong'),
                    style: TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PillButton(label: tr('Try again'), onPressed: _load),
                ],
              )
            else if (plan == null)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorsUtil.whiteColor,
                  ),
                ),
              )
            else
              ..._planView(plan),
          ],
        ),
      ),
    );
  }

  List<Widget> _planView(Plan plan) {
    final muted = TextStyle(
      color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
      fontSize: 15,
      height: 1.35,
    );
    const info = TextStyle(color: ColorsUtil.primaryLight, fontSize: 13);
    return [
      Text(
        plan.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ColorsUtil.whiteColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        [
          plan.place.name,
          plan.place.where,
        ].where((s) => s.isNotEmpty).join(', '),
        textAlign: TextAlign.center,
        style: muted,
      ),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 6,
        children: [
          _Info(
            icon: Icons.calendar_today,
            text:
                '${planDates(plan.startDate, plan.endDate)} · ${BookFormat.plural(plan.days, 'day')}',
            style: info,
          ),
          _Info(
            icon: Icons.person,
            text: [
              PlanOption.labelOf(PlanOptions.travellers, plan.travellers),
              PlanOption.labelOf(PlanOptions.paces, plan.pace),
              PlanOption.labelOf(PlanOptions.budgets, plan.budget),
            ].join(' · '),
            style: info,
          ),
        ],
      ),
      if (plan.summary.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(plan.summary, style: muted),
      ],
      const SizedBox(height: 16),
      EstimateCard(plan: plan),
      const SizedBox(height: 18),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          ShortcutPill(
            icon: Icons.flight,
            label: tr('Flights'),
            onPressed: () => _openFlights(plan),
          ),
          ShortcutPill(
            icon: Icons.hotel,
            label: tr('Stays'),
            onPressed: () => _openStays(plan),
          ),
          ShortcutPill(
            icon: Icons.directions_car,
            label: tr('Car rentals'),
            onPressed: () => _openCars(plan),
          ),
        ],
      ),
      const SizedBox(height: 22),
      for (final day in plan.dayPlans)
        DayCard(
          key: ValueKey('${day.day}-${day.title}'),
          day: day,
          currency: plan.currency,
          onChange: plan.mine
              ? (wish) async {
                  final changed = await PlanService.changeDay(
                    plan.id,
                    day.day,
                    wish,
                  );
                  if (mounted) setState(() => _plan = changed);
                }
              : null,
        ),
      if (plan.tips.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          tr('Tips for the trip'),
          style: TextStyle(
            color: ColorsUtil.whiteColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        for (final tip in plan.tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('•  $tip', style: muted),
          ),
      ],
      if (plan.mine)
        _OwnerActions(
          plan: plan,
          onChanged: (changed) => setState(() => _plan = changed),
          onDeleted: () => Navigator.of(context).maybePop(),
        ),
      const AiNote(),
    ];
  }

  void _push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  void _openFlights(Plan plan) {
    final airport = plan.airport;
    _push(
      Builder(
        builder: (context) => Scaffold(
          backgroundColor: ColorsUtil.primary,
          body: FlightSearchScreen(
            onClose: () => Navigator.of(context).maybePop(),
            to: airport == null
                ? null
                : Airport(
                    code: airport,
                    type: 'city',
                    name: plan.place.name,
                    country: plan.place.country,
                  ),
            depart: plan.startDate,
            returnDate: plan.endDate,
          ),
        ),
      ),
    );
  }

  void _openStays(Plan plan) {
    final party = PlanService.party(plan.travellers);
    _push(
      StayResultsScreen(
        search: StaySearch(
          place: plan.place.name,
          checkin: plan.startDate,
          checkout: PlanService.leaveDate(
            plan.startDate,
            plan.endDate,
            plan.days,
          ),
          adults: party.guests,
          rooms: party.rooms,
        ),
      ),
    );
  }

  void _openCars(Plan plan) {
    _push(
      RentalResultsScreen(
        search: CarSearch(
          place: plan.place.name,
          pickup: plan.startDate,
          dropoff: PlanService.leaveDate(
            plan.startDate,
            plan.endDate,
            plan.days,
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text, required this.style});

  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: style.color),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}

/// Share by link (the plan's page on the website), copy the link, stop sharing, and delete (tap twice).
class _OwnerActions extends StatefulWidget {
  const _OwnerActions({
    required this.plan,
    required this.onChanged,
    required this.onDeleted,
  });

  final Plan plan;
  final ValueChanged<Plan> onChanged;
  final VoidCallback onDeleted;

  @override
  State<_OwnerActions> createState() => _OwnerActionsState();
}

class _OwnerActionsState extends State<_OwnerActions> {
  bool _busy = false;
  bool _confirmDelete = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Copies the link; the link stays on screen to copy by hand if the clipboard refuses.
  Future<void> _copy(String link) async {
    var copied = true;
    try {
      await Clipboard.setData(ClipboardData(text: link));
    } on Object {
      copied = false;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied
                ? tr('Link copied')
                : tr('Couldn\'t copy the link. Select it to copy.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final link = PlanService.sharedLink(plan.id);
    return PlanPanel(
      children: [
        if (plan.shared) ...[
          Text(
            tr('Anyone with this link can view the plan:'),
            textAlign: TextAlign.center,
            style: TextStyle(color: ColorsUtil.whiteColor),
          ),
          const SizedBox(height: 6),
          SelectableText(
            link ?? tr('The website address is missing in this build.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColorsUtil.primaryLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (link != null)
                PillButton(
                  label: tr('Copy link'),
                  icon: Icons.link,
                  onPressed: () => _copy(link),
                ),
              PillButton(
                label: tr('Stop sharing'),
                quiet: true,
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        widget.onChanged(
                          await PlanService.share(plan.id, shared: false),
                        );
                      }),
              ),
            ],
          ),
        ] else
          PillButton(
            label: tr('Share by link'),
            large: true,
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final shared = await PlanService.share(
                      plan.id,
                      shared: true,
                    );
                    Analytics.track(const TripPlanShared());
                    widget.onChanged(shared);
                    final link = PlanService.sharedLink(shared.id);
                    if (link != null) unawaited(_copy(link));
                  }),
          ),
        const SizedBox(height: 12),
        PillButton(
          label: _confirmDelete
              ? tr('Tap again to delete this plan')
              : tr('Delete plan'),
          quiet: true,
          onPressed: _busy
              ? null
              : () {
                  if (!_confirmDelete) {
                    setState(() => _confirmDelete = true);
                    return;
                  }
                  _run(() async {
                    await PlanService.delete(plan.id);
                    widget.onDeleted();
                  });
                },
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorsUtil.secondaryLighter,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

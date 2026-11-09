import 'package:app_frontend/core/analytics/analytics.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/plans/plan_models.dart';
import 'package:app_frontend/core/plans/plan_service.dart';
import 'package:app_frontend/core/notifications/push_notifications.dart';
import 'package:app_frontend/features/04_hotels/utils/hotel_date_picker_util.dart';
import 'package:app_frontend/features/10_plans/screens/plan_screen.dart';
import 'package:app_frontend/features/10_plans/widgets/plan_widgets.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/book/form_error.dart';
import 'package:app_frontend/global_widgets/pill_button.dart';
import 'package:app_frontend/global_widgets/search_input_field.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Plan a trip" (the website's `PlanFormPage`): when, how long, who, pace, budget and interests for the place it
/// was opened from (a destination or a saved place in My Trips). The AI writes the plan (10-40 s), then the plan
/// opens in place of the form. Signed in only.
class PlanFormScreen extends StatefulWidget {
  const PlanFormScreen({super.key, required this.place});

  final PlanPlace place;

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _start = TextEditingController();
  final _days = TextEditingController(text: '3');
  String _travellers = 'couple';
  String _pace = 'balanced';
  String _budget = 'mid';
  List<String> _interests = [];
  String? _error;
  bool _planning = false;

  @override
  void initState() {
    super.initState();
    _days.addListener(_keepDaysInRange);
  }

  @override
  void dispose() {
    _start.dispose();
    _days.dispose();
    super.dispose();
  }

  int get _dayCount =>
      (int.tryParse(_days.text) ?? 1).clamp(1, PlanOptions.maxDays);

  /// The counter has no maximum of its own: hold it at [PlanOptions.maxDays].
  void _keepDaysInRange() {
    final value = int.tryParse(_days.text);
    if (value != null && value > PlanOptions.maxDays) {
      _days.text = '${PlanOptions.maxDays}';
    }
  }

  Future<void> _submit() async {
    if (_start.text.isEmpty) {
      setState(() => _error = 'Choose when your trip starts.');
      return;
    }
    final days = _dayCount;
    setState(() {
      _error = null;
      _planning = true;
    });
    try {
      final plan = await PlanService.create(
        PlanRequest(
          place: widget.place,
          startDate: _start.text,
          days: days,
          travellers: _travellers,
          pace: _pace,
          budget: _budget,
          interests: _interests,
        ),
      );
      Analytics.track(TripPlanCreated(days: days));
      if (!mounted) return;
      await PushNotifications.askAtUsefulMoment(
        context,
        'Get a reminder three days before your trip, and the day before.',
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PlanScreen(id: plan.id, plan: plan),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _planning = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final signedIn = context.watch<UserProvider>().user != null;
    final place = widget.place;

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
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: ColorsUtil.whiteColor,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.travel_explore,
                  color: ColorsUtil.whiteColor,
                  size: 26,
                ),
                SizedBox(width: 8),
                Text(
                  'Plan a trip',
                  style: TextStyle(
                    color: ColorsUtil.whiteColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              place.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (place.where.isNotEmpty)
              Text(
                place.where,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorsUtil.whiteColor.withValues(alpha: 0.75),
                ),
              ),
            if (!signedIn)
              PlanPanel(
                children: [
                  const Text(
                    'Sign in from the Profile tab to plan a trip. Your plans are saved in My Trips.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PillButton(
                    label: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              )
            else if (_planning)
              PlanPanel(
                children: [
                  const CircularProgressIndicator(
                    color: ColorsUtil.secondaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Planning your trip to ${place.name}…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ColorsUtil.whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Our AI is writing it day by day. This can take up to a minute.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              )
            else
              ..._form(),
          ],
        ),
      ),
    );
  }

  List<Widget> _form() {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: SearchInputField(
              icon: Icons.calendar_today,
              hint: 'Start date',
              controller: _start,
              onTap: () => HotelDatePickerUtils.selectDate(
                context,
                _start,
                () => setState(() => _error = null),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SearchInputField(
              icon: Icons.calendar_month,
              caption: 'Days',
              min: 1,
              controller: _days,
              isCounter: true,
            ),
          ),
        ],
      ),
      const _Label("Who's going?"),
      OptionChips(
        options: PlanOptions.travellers,
        selected: [_travellers],
        onChanged: (value) => setState(() => _travellers = value.first),
      ),
      const _Label('Pace'),
      OptionChips(
        options: PlanOptions.paces,
        selected: [_pace],
        onChanged: (value) => setState(() => _pace = value.first),
      ),
      const _Label('Budget'),
      OptionChips(
        options: PlanOptions.budgets,
        selected: [_budget],
        onChanged: (value) => setState(() => _budget = value.first),
      ),
      const _Label('Interests (up to ${PlanOptions.maxInterests})'),
      OptionChips(
        options: PlanOptions.interests,
        selected: _interests,
        max: PlanOptions.maxInterests,
        onChanged: (value) => setState(() => _interests = value),
      ),
      const SizedBox(height: 20),
      if (_error != null) FormError(_error!),
      Center(
        child: PillButton(
          label: 'Plan my trip',
          large: true,
          onPressed: _submit,
        ),
      ),
      const AiNote(),
    ];
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ColorsUtil.whiteColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

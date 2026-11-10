import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/book/book_format.dart';
import 'package:app_frontend/core/plans/plan_models.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/book/book_cards.dart';
import 'package:app_frontend/global_widgets/pill_button.dart';
import 'package:flutter/material.dart';

final _muted = TextStyle(
  color: ColorsUtil.whiteColor.withValues(alpha: 0.8),
  fontSize: 14,
  height: 1.35,
);

/// "≈ ₹500", or "Free" for nothing.
String _cost(int value, String currency) =>
    value > 0 ? '≈ ${BookFormat.price(value, currency)}' : tr('Free');

/// The plan form's chips: one choice ([selected] has one value) or several, up to [max].
class OptionChips extends StatelessWidget {
  const OptionChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.max,
  });

  final List<PlanOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// Set for a multi-choice list; unset, picking one replaces the choice.
  final int? max;

  @override
  Widget build(BuildContext context) {
    final multi = max != null;
    final full = multi && selected.length >= max!;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          Builder(
            builder: (context) {
              final on = selected.contains(option.value);
              return FilterChip(
                label: Text(option.label),
                selected: on,
                showCheckmark: true,
                checkmarkColor: ColorsUtil.whiteColor,
                onSelected: !on && full
                    ? null
                    : (_) => onChanged(
                        !multi
                            ? [option.value]
                            : on
                            ? selected.where((v) => v != option.value).toList()
                            : [...selected, option.value],
                      ),
                selectedColor: ColorsUtil.secondaryLight,
                backgroundColor: ColorsUtil.field,
                disabledColor: ColorsUtil.field.withValues(alpha: 0.4),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: const TextStyle(
                  color: ColorsUtil.whiteColor,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
      ],
    );
  }
}

/// The plan's rough costs, on the founder's two-tone card.
class EstimateCard extends StatelessWidget {
  const EstimateCard({super.key, required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final estimate = plan.estimate;
    String money(int value) => BookFormat.price(value, plan.currency);
    const big = TextStyle(
      color: ColorsUtil.whiteColor,
      fontSize: 17,
      fontWeight: FontWeight.bold,
    );
    final small = TextStyle(
      color: ColorsUtil.whiteColor.withValues(alpha: 0.85),
      fontSize: 12,
    );
    const line = TextStyle(color: ColorsUtil.whiteColor, fontSize: 14);
    return TwoToneCard(
      left: [
        Text(tr('≈ {0} a day', [money(estimate.perDay)]), style: big),
        const SizedBox(height: 4),
        Text(tr('Food, local transport and activities'), style: small),
      ],
      right: [
        if (estimate.nights > 0)
          Text(
            tr('Stays ≈ {0} a night', [money(estimate.stayPerNight)]),
            style: line,
          ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            style: line,
            children: [
              TextSpan(
                text: '≈ ${money(estimate.total)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: tr(' for the trip')),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('AI estimate for the group · flights not included'),
          style: small,
        ),
      ],
    );
  }
}

/// The founder's floating pill with an icon: a booking shortcut on a plan.
class ShortcutPill extends StatelessWidget {
  const ShortcutPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: ColorsUtil.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: ColorsUtil.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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

/// One day of a plan: an orange header with the date and title, then morning, afternoon and evening, food and a
/// tip. [onChange] (the owner only) rewrites the day, optionally following a wish.
class DayCard extends StatefulWidget {
  const DayCard({
    super.key,
    required this.day,
    required this.currency,
    this.onChange,
  });

  final DayPlan day;
  final String currency;
  final Future<void> Function(String wish)? onChange;

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  final _wish = TextEditingController();
  bool _open = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _wish.dispose();
    super.dispose();
  }

  Future<void> _rewrite() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onChange!(_wish.text.trim());
      if (!mounted) return;
      _wish.clear();
      setState(() => _open = false);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorsUtil.brandOrangeLight,
                  ColorsUtil.brandOrangeDark,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: tr('Day {0}   ', [day.day]),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: BookFormat.day(day.date)),
                    ],
                  ),
                  style: const TextStyle(
                    color: ColorsUtil.whiteColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.title,
                  style: const TextStyle(
                    color: ColorsUtil.whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SlotRow(
                  label: tr('MORNING'),
                  slot: day.morning,
                  currency: widget.currency,
                ),
                _SlotRow(
                  label: tr('AFTERNOON'),
                  slot: day.afternoon,
                  currency: widget.currency,
                ),
                _SlotRow(
                  label: tr('EVENING'),
                  slot: day.evening,
                  currency: widget.currency,
                ),
                if (day.food.isNotEmpty)
                  _Labelled(label: tr('Eat:'), text: day.food.join(' · ')),
                if (day.tip.isNotEmpty)
                  _Labelled(label: tr('Tip:'), text: day.tip),
                const SizedBox(height: 4),
                Text(
                  tr('Day total ≈ {0}', [
                    BookFormat.price(day.cost, widget.currency),
                  ]),
                  style: const TextStyle(
                    color: ColorsUtil.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onChange != null) ...[
                  const SizedBox(height: 12),
                  if (_open)
                    _changeForm()
                  else
                    PillButton(
                      label: tr('Change this day'),
                      quiet: true,
                      onPressed: () => setState(() => _open = true),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _changeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('What would you like instead? (optional)'),
          style: TextStyle(
            color: ColorsUtil.whiteColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _wish,
          enabled: !_busy,
          maxLength: 200,
          style: const TextStyle(color: ColorsUtil.primary),
          decoration: InputDecoration(
            hintText: tr('e.g. more street food, fewer museums'),
            filled: true,
            fillColor: ColorsUtil.whiteColor,
            counterStyle: _muted.copyWith(fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: const TextStyle(
                color: ColorsUtil.secondaryLighter,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_busy)
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorsUtil.whiteColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(tr('Rewriting this day…'), style: _muted),
            ],
          )
        else
          Wrap(
            spacing: 8,
            children: [
              PillButton(label: tr('Rewrite day'), onPressed: _rewrite),
              PillButton(
                label: tr('Cancel'),
                quiet: true,
                onPressed: () => setState(() {
                  _open = false;
                  _error = null;
                }),
              ),
            ],
          ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.label,
    required this.slot,
    required this.currency,
  });

  final String label;
  final Slot slot;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$label  ',
                        style: const TextStyle(
                          color: ColorsUtil.secondaryLighter,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      TextSpan(
                        text: slot.place,
                        style: const TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _cost(slot.cost, currency),
                style: _muted.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(slot.activity, style: _muted),
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.text});

  final String label, text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: text),
          ],
        ),
        style: const TextStyle(color: ColorsUtil.whiteColor, fontSize: 14),
      ),
    );
  }
}

/// A rounded, lightly tinted panel for messages and the owner's actions.
class PlanPanel extends StatelessWidget {
  const PlanPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: ColorsUtil.whiteColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}

/// The note under every plan and the plan form.
class AiNote extends StatelessWidget {
  const AiNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        tr(
          tr(
            'Plans are written by AI. Check opening times, prices and travel advice before you go.',
          ),
        ),
        textAlign: TextAlign.center,
        style: _muted.copyWith(fontSize: 12),
      ),
    );
  }
}

/// "10–12 Dec", or "Thu 10 Dec" for one day.
String planDates(String start, String end) =>
    start == end ? BookFormat.day(start) : BookFormat.dateRange(start, end);

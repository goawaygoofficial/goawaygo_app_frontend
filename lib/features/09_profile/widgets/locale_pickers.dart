import 'package:app_frontend/core/account/account_models.dart';
import 'package:app_frontend/core/account/account_service.dart';
import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The app's language for everyone, and (signed out) the currency prices are shown in; a signed-in account's
/// currency is in User Profile (4.7).
class LocalePickers extends StatefulWidget {
  const LocalePickers({super.key, required this.currency});

  /// Show the currency picker (signed out).
  final bool currency;

  @override
  State<LocalePickers> createState() => _LocalePickersState();
}

class _LocalePickersState extends State<LocalePickers> {
  List<CurrencyOption>? _currencies;
  String _chosen = I18n.currency;

  @override
  void initState() {
    super.initState();
    if (widget.currency) {
      AccountService.regions().then((regions) {
        if (mounted) setState(() => _currencies = regions.currencies);
      }, onError: (Object _) {});
    }
  }

  Widget _pill(String label, Widget field) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: ColorsUtil.textMuted)),
          const SizedBox(width: 10),
          Flexible(child: field),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    const style = TextStyle(
      color: ColorsUtil.whiteColor,
      fontWeight: FontWeight.w600,
    );
    final currencies =
        _currencies ?? [CurrencyOption(_chosen, _chosen, _chosen)];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        _pill(
          tr('Language'),
          DropdownButton<String>(
            key: const ValueKey('language-picker'),
            value: language.code,
            dropdownColor: ColorsUtil.primary,
            underline: const SizedBox.shrink(),
            iconEnabledColor: ColorsUtil.whiteColor,
            style: style,
            items: [
              for (final l in appLanguages)
                DropdownMenuItem(value: l.code, child: Text(l.name)),
            ],
            onChanged: (code) {
              if (code != null) language.change(code);
            },
          ),
        ),
        if (widget.currency)
          _pill(
            tr('Currency'),
            DropdownButton<String>(
              key: const ValueKey('currency-picker'),
              value: currencies.any((c) => c.code == _chosen) ? _chosen : null,
              isExpanded: false,
              dropdownColor: ColorsUtil.primary,
              underline: const SizedBox.shrink(),
              iconEnabledColor: ColorsUtil.whiteColor,
              style: style,
              menuMaxHeight: 400,
              items: [
                for (final c in currencies)
                  DropdownMenuItem(
                    value: c.code,
                    child: Text(c.code == c.name ? c.code : c.label),
                  ),
              ],
              onChanged: (code) {
                if (code == null) return;
                I18n.rememberCurrency(code);
                setState(() => _chosen = code);
              },
            ),
          ),
      ],
    );
  }
}

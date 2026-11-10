import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

/// Report a post, comment or person: pick a reason, add details if you like. The team reviews every report.
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required String target,
  required String label,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorsUtil.primary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _ReportSheet(targetType: targetType, target: target, label: label),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.targetType,
    required this.target,
    required this.label,
  });

  final String targetType, target, label;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _details = TextEditingController();
  String? _reason;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await WanderbookService.report(
        targetType: widget.targetType,
        target: widget.target,
        reason: _reason!,
        details: _details.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _sent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Thanks for telling us'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    tr(
                      'Our team will review it. You can also block the person so you don\'t see them.',
                    ),
                  ),
                  style: white,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('Done')),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Report {0}', [widget.label]),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: _reason,
                    onChanged: (value) => setState(() => _reason = value),
                    child: Column(
                      children: [
                        for (final entry in reportReasons.entries)
                          RadioListTile<String>(
                            value: entry.key,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: ColorsUtil.secondary,
                            title: Text(tr(entry.value), style: white),
                          ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _details,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: tr('Details (optional)'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: ColorsUtil.secondaryLighter,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          tr('Cancel'),
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _reason == null || _sending ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorsUtil.secondary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _sending ? tr('Sending…') : tr('Send report'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';

/// An orange User Profile row: label on the left, value on the right, and an Edit button when it can be changed.
class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final bool isObscured;

  /// Shown under the row (e.g. a new email waiting for its link).
  final String? note;

  /// Absent: the row can't be changed here.
  final VoidCallback? onEdit;
  final String editLabel;

  const ProfileField({
    super.key,
    required this.label,
    required this.value,
    this.isObscured = false,
    this.note,
    this.onEdit,
    this.editLabel = 'Edit',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              onEdit == null ? 14 : 8,
              onEdit == null ? 16 : 8,
              onEdit == null ? 14 : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9A5B),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Semantics(
                    label: isObscured ? 'Hidden' : null,
                    excludeSemantics: isObscured,
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: '$editLabel $label',
                    excludeSemantics: true,
                    child: OutlinedButton(
                      key: ValueKey('edit-$label'),
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(editLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                note!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

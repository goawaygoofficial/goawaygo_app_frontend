import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:flutter/material.dart';

/// A list loaded page by page ("Load more"). [onChanged] is called whenever it changes (usually `setState`).
class PagedLoader<T> {
  PagedLoader(this._fetch, this.onChanged);

  final Future<Paged<T>> Function(int? cursor) _fetch;
  final VoidCallback onChanged;

  /// Null while the first page loads.
  List<T>? items;
  String? error;
  int? _cursor;
  bool loadingMore = false;
  int _generation = 0;

  bool get hasMore => _cursor != null;

  /// Loads the first page again (answers to an earlier load are ignored).
  Future<void> reload() async {
    final generation = ++_generation;
    try {
      final page = await _fetch(null);
      if (generation != _generation) return;
      items = page.items;
      _cursor = page.nextCursor;
      error = null;
    } on ApiException catch (failure) {
      if (generation != _generation) return;
      error = failure.message;
    }
    onChanged();
  }

  Future<void> loadMore() async {
    if (_cursor == null || loadingMore) return;
    final generation = _generation;
    loadingMore = true;
    onChanged();
    try {
      final page = await _fetch(_cursor);
      if (generation == _generation) {
        items = [...?items, ...page.items];
        _cursor = page.nextCursor;
      }
    } on ApiException {
      // Keep what is shown; the button stays to try again.
    }
    loadingMore = false;
    onChanged();
  }

  void update(List<T> Function(List<T> items) change) {
    if (items == null) return;
    items = change(items!);
    onChanged();
  }

  /// The "Load more" button, when there is more.
  Widget moreButton() => !hasMore
      ? const SizedBox.shrink()
      : Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: PillButton(
              label: loadingMore ? tr('Loading…') : tr('Load more'),
              quiet: true,
              onPressed: loadingMore ? null : loadMore,
            ),
          ),
        );
}

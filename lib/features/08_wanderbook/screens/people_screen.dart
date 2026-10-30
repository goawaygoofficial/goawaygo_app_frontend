import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/paged_loader.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';

enum PeopleMode {
  followers('Followers'),
  following('Following'),
  requests('Follow requests'),
  blocked('Blocked people');

  const PeopleMode(this.title);

  final String title;
}

/// Followers or following of a profile; your follow requests (approve or decline); people you blocked.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key, required this.mode, this.publicId});

  final PeopleMode mode;

  /// The profile whose followers or following are shown.
  final String? publicId;

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late final _people = PagedLoader<Person>(_fetch, () {
    if (mounted) setState(() {});
  });
  String? _myPublicId;

  Future<Paged<Person>> _fetch(int? cursor) async {
    switch (widget.mode) {
      case PeopleMode.requests:
        return WanderbookService.followRequests(cursor);
      case PeopleMode.blocked:
        return Paged(await WanderbookService.blocked(), null);
      case PeopleMode.followers || PeopleMode.following:
        return WanderbookService.follows(
          widget.publicId!,
          widget.mode.name,
          cursor,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _people.reload();
    if (widget.mode == PeopleMode.followers) {
      // On your own followers list, each follower can be removed.
      WanderbookService.myProfile().then(
        (me) => mounted ? setState(() => _myPublicId = me.publicId) : null,
        onError: (Object _) => null,
      );
    }
  }

  Future<void> _run(Future<void> action, Person person) async {
    try {
      await action;
      _people.update(
        (all) => all.where((p) => p.publicId != person.publicId).toList(),
      );
    } on ApiException catch (error) {
      if (mounted) showError(context, error);
    }
  }

  Widget? _actions(Person person) {
    switch (widget.mode) {
      case PeopleMode.requests:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PillButton(
              label: 'Approve',
              onPressed: () => _run(
                WanderbookService.answerFollowRequest(person.publicId, true),
                person,
              ),
            ),
            const SizedBox(width: 6),
            PillButton(
              label: 'Decline',
              quiet: true,
              onPressed: () => _run(
                WanderbookService.answerFollowRequest(person.publicId, false),
                person,
              ),
            ),
          ],
        );
      case PeopleMode.blocked:
        return PillButton(
          label: 'Unblock',
          quiet: true,
          onPressed: () =>
              _run(WanderbookService.block(person.publicId, false), person),
        );
      case PeopleMode.followers when _myPublicId == widget.publicId:
        return PillButton(
          label: 'Remove',
          quiet: true,
          onPressed: () =>
              _run(WanderbookService.removeFollower(person.publicId), person),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _people.items;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      appBar: AppBar(
        backgroundColor: ColorsUtil.primary,
        foregroundColor: Colors.white,
        title: Text(widget.mode.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_people.error != null) StatusText(_people.error!),
          if (items == null && _people.error == null)
            const StatusText('Loading…'),
          if (items != null && items.isEmpty)
            const StatusText('Nobody here yet.'),
          for (final person in items ?? <Person>[])
            PersonTile(person: person, trailing: _actions(person)),
          _people.moreButton(),
        ],
      ),
    );
  }
}

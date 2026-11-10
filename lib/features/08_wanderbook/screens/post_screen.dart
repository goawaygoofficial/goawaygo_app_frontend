import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/paged_loader.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/place_fields.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/post_card.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/report_sheet.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One post with its comments; its author can edit the caption and place here.
class PostScreen extends StatefulWidget {
  const PostScreen({
    super.key,
    required this.publicId,
    this.startEditing = false,
    this.preview,
  });

  final String publicId;
  final bool startEditing;

  /// The post as the previous screen showed it, drawn at once (its photo flies in) until the fresh copy arrives.
  final Post? preview;

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late final _comments = PagedLoader<Comment>(
    (cursor) => WanderbookService.comments(widget.publicId, cursor),
    () {
      if (mounted) setState(() {});
    },
  );
  final _newComment = TextEditingController();
  late Post? _post = widget.preview;
  String? _error;
  late bool _editing = widget.startEditing;
  List<Person>? _likers;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _comments.reload();
  }

  @override
  void dispose() {
    _newComment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final post = await WanderbookService.post(widget.publicId);
      if (mounted) setState(() => _post = post);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _addComment() async {
    final text = _newComment.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final comment = await WanderbookService.addComment(widget.publicId, text);
      _newComment.clear();
      _comments.update((all) => [...all, comment]);
      final post = _post;
      if (post != null) {
        setState(() => _post = post.copyWith(comments: post.comments + 1));
      }
    } on ApiException catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      await WanderbookService.deleteComment(comment.id);
      _comments.update((all) => all.where((c) => c.id != comment.id).toList());
      final post = _post;
      if (post != null) {
        setState(() => _post = post.copyWith(comments: post.comments - 1));
      }
    } on ApiException catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final signedIn = context.watch<UserProvider>().user != null;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      appBar: AppBar(
        backgroundColor: ColorsUtil.primary,
        foregroundColor: Colors.white,
        title: Text(_editing ? tr('Edit post') : tr('Post')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) StatusText(_error!),
            if (post == null && _error == null) StatusText(tr('Loading…')),
            if (post != null && _editing && post.isYours)
              _EditPost(
                post: post,
                onDone: (saved) => setState(() {
                  if (saved != null) _post = saved;
                  _editing = false;
                }),
              ),
            if (post != null && !(_editing && post.isYours)) ...[
              PostCard(
                post: post,
                full: true,
                onChanged: (changed) => setState(() => _post = changed),
                onDeleted: () => Navigator.of(context).pop(),
              ),
              if (post.likes > 0)
                TextButton(
                  onPressed: () async {
                    if (_likers != null) {
                      setState(() => _likers = null);
                      return;
                    }
                    try {
                      final likers = await WanderbookService.likes(
                        post.publicId,
                      );
                      if (mounted) setState(() => _likers = likers);
                    } on ApiException catch (error) {
                      if (context.mounted) showError(context, error);
                    }
                  },
                  child: Text(
                    _likers == null
                        ? tr('See who liked this')
                        : tr('Hide likes'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              if (_likers != null)
                for (final person in _likers!) PersonTile(person: person),
              const Divider(color: Colors.white24),
              Text(
                tr('Comments'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_comments.items?.isEmpty ?? false)
                StatusText(tr('No comments yet.')),
              for (final comment in _comments.items ?? <Comment>[])
                _CommentTile(
                  comment: comment,
                  onDelete: () => _deleteComment(comment),
                  onReport: signedIn && !comment.canDelete
                      ? () => showReportSheet(
                          context,
                          targetType: 'comment',
                          target: '${comment.id}',
                          label: tr('this comment'),
                        )
                      : null,
                ),
              _comments.moreButton(),
              const SizedBox(height: 8),
              if (signedIn)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newComment,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: tr('Add a comment…'),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: tr('Post comment'),
                      onPressed: _sending ? null : _addComment,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                )
              else
                StatusText(tr('Sign in from the Profile tab to comment.')),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onDelete,
    this.onReport,
  });

  final Comment comment;
  final VoidCallback onDelete;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: 12,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => openProfile(
              context,
              comment.author.publicId,
              preview: comment.author,
            ),
            child: Avatar(url: comment.author.photoUrl, size: 32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${comment.author.name} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: comment.text),
                    ],
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                Row(
                  children: [
                    Text(timeAgo(comment.createdAt), style: muted),
                    if (comment.canDelete)
                      TextButton(
                        onPressed: onDelete,
                        child: Text(tr('Delete'), style: muted),
                      ),
                    if (onReport != null)
                      TextButton(
                        onPressed: onReport,
                        child: Text(tr('Report'), style: muted),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPost extends StatefulWidget {
  const _EditPost({required this.post, required this.onDone});

  final Post post;
  final ValueChanged<Post?> onDone;

  @override
  State<_EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<_EditPost> {
  late final _caption = TextEditingController(text: widget.post.caption);
  late PlaceTag? _place = widget.post.place;
  bool _saving = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await WanderbookService.editPost(
        widget.post.publicId,
        caption: _caption.text.trim(),
        place: _place,
      );
      widget.onDone(saved);
    } on ApiException catch (error) {
      if (mounted) {
        showError(context, error);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _caption,
          maxLength: 2200,
          maxLines: 6,
          minLines: 3,
          decoration: InputDecoration(
            labelText: tr('Caption'),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
        ),
        PlaceFields(value: _place, onChanged: (place) => _place = place),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PillButton(
              label: tr('Cancel'),
              quiet: true,
              onPressed: () => widget.onDone(null),
            ),
            const SizedBox(width: 8),
            PillButton(
              label: _saving ? tr('Saving…') : tr('Save'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ],
    );
  }
}

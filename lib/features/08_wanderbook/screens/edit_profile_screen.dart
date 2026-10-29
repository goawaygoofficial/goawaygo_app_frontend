import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/legal/legal_pages.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/features/08_wanderbook/screens/people_screen.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Edit your Wanderbook profile: photo, cover, bio, home town, and whether it is private.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _bio = TextEditingController();
  final _homeTown = TextEditingController();
  Profile? _profile;
  bool _isPrivate = false;
  String? _busy;

  @override
  void initState() {
    super.initState();
    WanderbookService.myProfile().then((profile) {
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _bio.text = profile.bio;
        _homeTown.text = profile.homeTown;
        _isPrivate = profile.isPrivate;
      });
    }, onError: (Object error) => mounted ? showError(context, error) : null);
  }

  @override
  void dispose() {
    _bio.dispose();
    _homeTown.dispose();
    super.dispose();
  }

  /// [kind] `avatar` or `cover`; [remove] clears it instead of picking a new one.
  Future<void> _changePhoto(String kind, {bool remove = false}) async {
    String? photoId;
    setState(() => _busy = kind);
    try {
      if (!remove) {
        final file = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (file == null) return;
        final uploaded = await WanderbookService.uploadPhoto(
          await file.readAsBytes(),
          file.name,
        );
        photoId = uploaded.photo.id;
      }
      final profile = await WanderbookService.setProfilePhoto(kind, photoId);
      if (!mounted) return;
      setState(() => _profile = profile);
      // The profile photo is also the account photo.
      if (kind == 'avatar') await context.read<UserProvider>().reloadUser();
    } on ApiException catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = 'save');
    try {
      final profile = await WanderbookService.updateMyProfile(
        bio: _bio.text.trim(),
        homeTown: _homeTown.text.trim(),
        isPrivate: _isPrivate,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved.')));
    } on ApiException catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _open(PeopleMode mode) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => PeopleScreen(mode: mode)));
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      appBar: AppBar(
        backgroundColor: ColorsUtil.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit profile'),
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Avatar(url: profile.photoUrl, size: 72),
                    const SizedBox(width: 12),
                    PillButton(
                      label: _busy == 'avatar'
                          ? 'Uploading…'
                          : 'Change profile photo',
                      quiet: true,
                      onPressed: _busy == null
                          ? () => _changePhoto('avatar')
                          : null,
                    ),
                    if (profile.photoUrl != null)
                      TextButton(
                        onPressed: _busy == null
                            ? () => _changePhoto('avatar', remove: true)
                            : null,
                        child: const Text(
                          'Remove',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 110,
                        height: 62,
                        child: profile.coverUrl == null
                            ? const ColoredBox(color: Colors.white12)
                            : Image.network(
                                profile.coverUrl!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PillButton(
                      label: _busy == 'cover' ? 'Uploading…' : 'Change cover',
                      quiet: true,
                      onPressed: _busy == null
                          ? () => _changePhoto('cover')
                          : null,
                    ),
                    if (profile.coverUrl != null)
                      TextButton(
                        onPressed: _busy == null
                            ? () => _changePhoto('cover', remove: true)
                            : null,
                        child: const Text(
                          'Remove',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _bio,
                  maxLength: 150,
                  maxLines: 3,
                  decoration: _decoration('Bio'),
                ),
                TextField(
                  controller: _homeTown,
                  maxLength: 100,
                  decoration: _decoration('Home town'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: ColorsUtil.secondary,
                  value: _isPrivate,
                  onChanged: (value) => setState(() => _isPrivate = value),
                  title: const Text(
                    'Private profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Only followers you approve see your posts and lists. Turning it off approves waiting '
                    'requests.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PillButton(
                  label: _busy == 'save' ? 'Saving…' : 'Save',
                  onPressed: _busy == null ? _save : null,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _open(PeopleMode.requests),
                      child: const Text('Follow requests'),
                    ),
                    TextButton(
                      onPressed: () => _open(PeopleMode.blocked),
                      child: const Text('Blocked people'),
                    ),
                    TextButton(
                      onPressed: () =>
                          openLegalPage(context, LegalPage.communityGuidelines),
                      child: const Text('Community Guidelines'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

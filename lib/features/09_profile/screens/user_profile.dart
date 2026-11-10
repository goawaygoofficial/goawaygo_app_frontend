import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/account/account_models.dart';
import 'package:app_frontend/core/account/account_service.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/features/01_auth_register/sign_out.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/09_profile/widgets/account_sheets.dart';
import 'package:app_frontend/features/09_profile/widgets/profile_field.dart';
import 'package:app_frontend/features/11_notifications/screens/notification_settings_screen.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// The account (Me, 4.6): photo and name (the same as on Wanderbook), email, password, country and currency, each
/// changed in a sheet; notification settings, sign out, and delete account.
class UserProfilePage extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onClose;
  const UserProfilePage({super.key, this.user, required this.onClose});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  static const _notSet = 'Not set';

  String? _message;
  bool _photoBusy = false;
  Regions? _regions;

  @override
  void initState() {
    super.initState();
    // Country names for the row; the codes are shown until they load.
    AccountService.regions().then((regions) {
      if (mounted) setState(() => _regions = regions);
    }, onError: (Object _) {});
  }

  Future<void> _edit(
    Future<String?> Function(BuildContext, UserModel) sheet,
  ) async {
    final user = widget.user;
    if (user == null) return;
    setState(() => _message = null);
    final message = await sheet(context, user);
    if (message != null && mounted) setState(() => _message = message);
  }

  Future<void> _delete() async {
    final user = widget.user;
    if (user == null) return;
    final deleteOn = await AccountSheets.delete(context, user);
    if (deleteOn == null || !mounted) return;
    widget.onClose();
    await CustomDialogs.showSuccessDialog(
      context: context,
      message: tr(
        tr(
          'Your account will be deleted on {0}. Sign in before then to keep it.',
        ),
        [deleteOn],
      ),
    );
  }

  Future<void> _changePhoto({bool remove = false}) async {
    final users = context.read<UserProvider>();
    setState(() {
      _photoBusy = true;
      _message = null;
    });
    try {
      String? photoId;
      if (!remove) {
        final file = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (file == null) return;
        final uploaded = await WanderbookService.uploadPhoto(
          await file.readAsBytes(),
          file.name,
        );
        photoId = uploaded.photo.id;
      }
      await WanderbookService.setProfilePhoto('avatar', photoId);
      await users.reloadUser();
      if (mounted) {
        setState(
          () => _message = remove
              ? tr('Photo removed.')
              : tr('Photo changed. Wanderbook shows it too.'),
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final user = widget.user;
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(width * 0.01),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: width * 0.2,
                    height: height * 0.12,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/user_profile.png',
                          width: width * 0.08,
                          height: height * 0.06,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tr('User Profile'),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Balances the logo so the title stays centred (notifications are on Home only).
                  SizedBox(width: width * 0.2),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (user != null) _photoRow(user),
                  if (_message != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ColorsUtil.whiteColor),
                      ),
                    ),
                  ProfileField(
                    label: tr('Display Name'),
                    value: user?.name ?? tr(_notSet),
                    onEdit: user == null
                        ? null
                        : () => _edit(AccountSheets.name),
                  ),
                  ProfileField(
                    label: tr('Email'),
                    value: user?.email ?? tr(_notSet),
                    note: user?.pendingEmail == null
                        ? null
                        : tr('Waiting for you to open the link sent to {0}.', [
                            user!.pendingEmail,
                          ]),
                    editLabel: tr('Change'),
                    onEdit: user == null
                        ? null
                        : () => _edit(AccountSheets.email),
                  ),
                  ProfileField(
                    label: tr('Password'),
                    value: user?.hasPassword == false
                        ? tr('Google sign-in')
                        : '**************',
                    isObscured: user?.hasPassword != false,
                    editLabel: user?.hasPassword == false
                        ? tr('Set')
                        : tr('Change'),
                    onEdit: user == null
                        ? null
                        : () => _edit(AccountSheets.password),
                  ),
                  ProfileField(
                    label: tr('Phone Number'),
                    value: user?.phone ?? tr(_notSet),
                  ),
                  ProfileField(
                    label: tr('Country / Region'),
                    value: user?.country == null
                        ? tr(_notSet)
                        : (_regions?.countryName(user!.country) ??
                              user!.country!),
                    onEdit: user == null
                        ? null
                        : () => _edit(AccountSheets.country),
                  ),
                  ProfileField(
                    label: tr('Currency'),
                    value: user?.currency ?? tr(_notSet),
                    onEdit: user == null
                        ? null
                        : () => _edit(AccountSheets.currency),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_outlined),
                      label: Text(
                        tr('Notification settings'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorsUtil.whiteColor,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => confirmAndSignOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsUtil.secondary,
                        foregroundColor: ColorsUtil.whiteColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        tr('Sign Out'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: widget.onClose,
                      child: Text(
                        tr('Back'),
                        style: TextStyle(
                          color: ColorsUtil.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (user != null) ...[
                    const Divider(color: Colors.white24, height: 32),
                    Center(
                      child: TextButton(
                        onPressed: _delete,
                        child: Text(
                          tr('Delete account'),
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoRow(UserModel user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Avatar(url: user.profilePicture, size: 80),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton(
                onPressed: _photoBusy ? null : () => _changePhoto(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsUtil.whiteColor,
                  side: const BorderSide(color: Colors.white70),
                  shape: const StadiumBorder(),
                ),
                child: Text(_photoBusy ? tr('Uploading…') : tr('Change photo')),
              ),
              if (user.profilePicture != null && !_photoBusy)
                TextButton(
                  onPressed: () => _changePhoto(remove: true),
                  child: Text(
                    tr('Remove'),
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:app_frontend/core/i18n/i18n.dart';
import 'package:app_frontend/core/account/account_models.dart';
import 'package:app_frontend/core/account/account_service.dart';
import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/features/01_auth_register/services/auth_service.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:app_frontend/global_widgets/custom_dialog.dart';
import 'package:app_frontend/models/user_model.dart';
import 'package:app_frontend/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The User Profile's edit forms (Me, 4.6), each in a bottom sheet. Each resolves with a message to show on the
/// page once saved, or null if the sheet was closed.
class AccountSheets {
  AccountSheets._();

  static Future<String?> _open(BuildContext context, Widget sheet) {
    // The sheet is a new route: give it the same signed-in user wherever the providers sit.
    final users = context.read<UserProvider>();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorsUtil.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ChangeNotifierProvider.value(value: users, child: sheet),
    );
  }

  static Future<String?> name(BuildContext context, UserModel user) =>
      _open(context, _NameSheet(user: user));

  static Future<String?> email(BuildContext context, UserModel user) =>
      _open(context, _EmailSheet(user: user));

  static Future<String?> password(BuildContext context, UserModel user) =>
      _open(context, _PasswordSheet(user: user));

  static Future<String?> country(BuildContext context, UserModel user) =>
      _open(context, _RegionSheet(user: user, currency: false));

  static Future<String?> currency(BuildContext context, UserModel user) =>
      _open(context, _RegionSheet(user: user, currency: true));

  /// Resolves with the date the account will be deleted (the session has ended), or null if not deleted.
  static Future<String?> delete(BuildContext context, UserModel user) =>
      _open(context, _DeleteSheet(user: user));
}

InputDecoration _input(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide.none,
  ),
);

/// Title, fields, the error and the button, above the keyboard.
class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.title,
    required this.children,
    required this.error,
    required this.button,
    required this.busy,
    required this.onSubmit,
    this.danger = false,
  });

  final String title;
  final List<Widget> children;
  final String? error;
  final String button;
  final bool busy;
  final VoidCallback onSubmit;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            for (final child in children) ...[
              child,
              const SizedBox(height: 12),
            ],
            if (error != null) ...[
              Text(
                '⚠ $error',
                style: const TextStyle(
                  color: ColorsUtil.whiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Center(
              child: ElevatedButton(
                onPressed: busy ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger
                      ? Colors.red.shade700
                      : ColorsUtil.secondary,
                  foregroundColor: ColorsUtil.whiteColor,
                  disabledBackgroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        button,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs [action] with the busy flag and the error shown in the sheet.
mixin _Submitting<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  Future<void> submit(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } on _Invalid catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _Invalid implements Exception {
  const _Invalid(this.message);
  final String message;
}

/// "Confirm it's you": the current password field, or (accounts without one) Google's account picker.
class _ProofField extends StatelessWidget {
  const _ProofField({required this.user, required this.controller});

  final UserModel user;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    if (!user.hasPassword) {
      return Text(
        tr('To confirm it’s you, Google asks you to pick your account.'),
        style: TextStyle(color: ColorsUtil.textMuted),
      );
    }
    return TextField(
      controller: controller,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      decoration: _input(tr('Current password')),
    );
  }
}

/// The proof, or null if the Google picker was closed.
Future<Proof?> _proof(UserModel user, TextEditingController password) async {
  if (user.hasPassword) {
    if (password.text.isEmpty) {
      throw _Invalid(tr('Enter your current password.'));
    }
    return Proof.password(password.text);
  }
  final idToken = await AuthService.googleIdToken();
  return idToken == null ? null : Proof.google(idToken);
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.user});
  final UserModel user;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> with _Submitting {
  late final _name = TextEditingController(text: widget.user.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      title: tr('Display name'),
      error: error,
      busy: busy,
      button: tr('Save'),
      onSubmit: () => submit(() async {
        final name = _name.text.trim();
        if (name.isEmpty) throw _Invalid(tr('Enter your name.'));
        final users = context.read<UserProvider>();
        final navigator = Navigator.of(context);
        final saved = await AccountService.updateDetails(
          name: name,
          country: widget.user.country,
          currency: widget.user.currency,
        );
        users.signIn(saved);
        navigator.pop(tr('Name saved. Wanderbook shows it too.'));
      }),
      children: [
        TextField(
          controller: _name,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: _input(tr('Your name')).copyWith(counterText: ''),
        ),
      ],
    );
  }
}

class _EmailSheet extends StatefulWidget {
  const _EmailSheet({required this.user});
  final UserModel user;

  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> with _Submitting {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      title: tr('Change email'),
      error: error,
      busy: busy,
      button: tr('Send confirmation link'),
      onSubmit: () => submit(() async {
        final email = _email.text.trim();
        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
          throw _Invalid(tr('Enter a valid email address.'));
        }
        final users = context.read<UserProvider>();
        final navigator = Navigator.of(context);
        final proof = await _proof(widget.user, _password);
        if (proof == null) return;
        users.signIn(await AccountService.changeEmail(proof, email));
        navigator.pop(
          tr('We sent a link to {0}. Your email changes when you open it.', [
            email,
          ]),
        );
      }),
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: _input(tr('New email')),
        ),
        _ProofField(user: widget.user, controller: _password),
      ],
    );
  }
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({required this.user});
  final UserModel user;

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> with _Submitting {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = widget.user.hasPassword;
    return _SheetBody(
      title: hasPassword ? tr('Change password') : tr('Set a password'),
      error: error,
      busy: busy,
      button: hasPassword ? tr('Change password') : tr('Set password'),
      onSubmit: () => submit(() async {
        final password = _password.text;
        if (password.length < 8 || password.length > 72) {
          throw _Invalid(tr('The new password must be 8 to 72 characters.'));
        }
        if (password != _repeat.text) {
          throw _Invalid(tr('The two new passwords don’t match.'));
        }
        final users = context.read<UserProvider>();
        final navigator = Navigator.of(context);
        final proof = await _proof(widget.user, _current);
        if (proof == null) return;
        users.signIn(await AccountService.changePassword(proof, password));
        navigator.pop(
          hasPassword
              ? tr('Password changed. Your other devices were signed out.')
              : tr('Password set. You can now also sign in with your email.'),
        );
      }),
      children: [
        _ProofField(user: widget.user, controller: _current),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: _input(tr('New password (8+ characters)')),
        ),
        TextField(
          controller: _repeat,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: _input(tr('Repeat the new password')),
        ),
      ],
    );
  }
}

/// A searchable list of countries or currencies; picking one saves it at once.
class _RegionSheet extends StatefulWidget {
  const _RegionSheet({required this.user, required this.currency});
  final UserModel user;
  final bool currency;

  @override
  State<_RegionSheet> createState() => _RegionSheetState();
}

class _RegionSheetState extends State<_RegionSheet> with _Submitting {
  Regions? _regions;
  String _query = '';

  @override
  void initState() {
    super.initState();
    AccountService.regions().then(
      (regions) {
        if (mounted) setState(() => _regions = regions);
      },
      onError: (Object e) {
        if (mounted) {
          setState(
            () => error = e is ApiException
                ? e.message
                : tr('Could not load the list.'),
          );
        }
      },
    );
  }

  Future<void> _pick(String? code) => submit(() async {
    final user = widget.user;
    final users = context.read<UserProvider>();
    final UserModel saved;
    if (widget.currency) {
      saved = await AccountService.updateDetails(
        name: user.name,
        country: user.country,
        currency: code,
      );
    } else {
      // Picking a country for the first time also picks its currency.
      final countryCurrency = _regions?.countries
          .where((c) => c.code == code)
          .map((c) => c.currency)
          .firstOrNull;
      saved = await AccountService.updateDetails(
        name: user.name,
        country: code,
        currency: user.currency ?? countryCurrency,
      );
    }
    users.signIn(saved);
    if (!mounted) return;
    final what = widget.currency ? tr('Currency') : tr('Country');
    Navigator.of(context).pop(code == null ? '$what cleared.' : '$what saved.');
  });

  @override
  Widget build(BuildContext context) {
    final regions = _regions;
    final selected = widget.currency
        ? widget.user.currency
        : widget.user.country;
    final query = _query.toLowerCase();
    final options = regions == null
        ? <(String, String)>[]
        : widget.currency
        ? [
            for (final c in regions.currencies)
              if (query.isEmpty || c.label.toLowerCase().contains(query))
                (c.code, c.label),
          ]
        : [
            for (final c in regions.countries)
              if (query.isEmpty || c.name.toLowerCase().contains(query))
                (c.code, c.name),
          ];
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              widget.currency ? tr('Currency') : tr('Country / Region'),
              style: TextStyle(
                color: ColorsUtil.whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: _input(
                widget.currency
                    ? tr('Search currencies')
                    : tr('Search countries'),
              ).copyWith(prefixIcon: Icon(Icons.search)),
            ),
            if (error != null)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '⚠ $error',
                  style: TextStyle(
                    color: ColorsUtil.whiteColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(height: 8),
            Expanded(
              child: regions == null
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : ListView(
                      children: [
                        if (query.isEmpty)
                          _option(null, tr('Not set'), selected == null),
                        for (final (code, label) in options)
                          _option(code, label, code == selected),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(String? code, String label, bool isSelected) {
    return ListTile(
      enabled: !busy,
      onTap: () => _pick(code),
      title: Text(
        label,
        style: TextStyle(
          color: ColorsUtil.whiteColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: ColorsUtil.brandOrangeLight)
          : null,
    );
  }
}

class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet({required this.user});
  final UserModel user;

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> with _Submitting {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// "9 December 2026", as the traveller's locale writes dates.
  static String _day(DateTime? date) {
    if (date == null) return tr('in 30 days');
    return DateFormat.yMMMMd(I18n.locale).format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      title: tr('Delete account'),
      error: error,
      busy: busy,
      danger: true,
      button: tr('Delete my account'),
      onSubmit: () => submit(() async {
        final navigator = Navigator.of(context);
        final proof = await _proof(widget.user, _password);
        if (proof == null || !mounted) return;
        final sure = await CustomDialogs.showConfirmDialog(
          context: this.context,
          message: tr(
            tr(
              'Delete your GoAwayGo account? You can still keep it by signing in within 30 days.',
            ),
          ),
          confirmLabel: tr('Delete'),
        );
        if (!sure) return;
        final deleteOn = await AccountService.deleteAccount(proof);
        navigator.pop(_day(deleteOn));
      }),
      children: [
        Text(
          tr(
            tr(
              'Your account is hidden from others and signed out at once. Sign in within 30 days to keep it; after that, your posts, photos, trip plans and everything else are deleted for good.',
            ),
          ),
          style: TextStyle(color: ColorsUtil.textMuted, height: 1.4),
        ),
        _ProofField(user: widget.user, controller: _password),
      ],
    );
  }
}

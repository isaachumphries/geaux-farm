import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../../core/http.dart';
import '../data/auth_providers.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/username.dart';

/// The community write action that asked the user to sign in. Sets the
/// sheet's title on the email step (CM-04).
enum SignInAction {
  star('Sign in to star guides', Symbols.star_rounded),
  grow('Sign in to grow guides', Symbols.potted_plant_rounded),
  remix('Sign in to remix guides', Symbols.content_copy_rounded),
  publish('Sign in to publish guides', Symbols.edit_rounded),
  report('Sign in to report guides', Symbols.flag_rounded);

  const SignInAction(this.title, this.icon);

  final String title;
  final IconData icon;
}

/// Runs [action] now when the user is signed in with a profile; otherwise
/// opens the CM-04 sheet and runs [action] once, after the sheet closes
/// having completed sign-in. Dismissing the sheet never runs it.
Future<void> requireSignIn(
  BuildContext context,
  WidgetRef ref, {
  required SignInAction reason,
  required VoidCallback action,
}) async {
  // Riverpod pauses a provider nobody listens to, and read() isn't
  // listening, so hold a listener while waiting for the first value.
  final subscription = ref.listenManual(authStateProvider, (_, _) {});
  AuthUser? user;
  try {
    user = await ref.read(authStateProvider.future);
  } on Object {
    user = null;
  } finally {
    subscription.close();
  }
  if (user != null && user.hasProfile) {
    action();
    return;
  }
  if (!context.mounted) return;
  final signedIn = await showSignInSheet(context, reason: reason);
  if (signedIn) action();
}

/// Shows the CM-04 sheet. Completes with true when sign-in finished
/// (including the username step), false when the user dismissed it.
Future<bool> showSignInSheet(
  BuildContext context, {
  SignInAction reason = SignInAction.star,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) => SignInSheet(
      reason: reason,
      onSignedIn: () => Navigator.of(sheetContext).pop(true),
    ),
  );
  return done ?? false;
}

enum _Step { email, code, username }

const _codeLength = 6;
const _resendCooldown = Duration(seconds: 60);

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// CM-04: email → 6-digit code → username (first sign-in only). Calls
/// [onSignedIn] exactly once when the flow completes.
class SignInSheet extends ConsumerStatefulWidget {
  const SignInSheet({
    super.key,
    required this.onSignedIn,
    this.reason = SignInAction.star,
  });

  final SignInAction reason;
  final VoidCallback onSignedIn;

  static const subtitle = 'We’ll email you a 6-digit code. No password needed.';
  static const invalidEmail = 'Enter a valid email address.';
  static const invalidCode =
      'That code didn’t work. Check it or send a new one.';
  static const nameTaken = 'That name is taken';
  static const rateLimited = 'Too many tries. Wait a minute and try again.';
  static const offline = 'No connection. Check your network and try again.';
  static const generic = 'Something went wrong. Try again.';

  @override
  ConsumerState<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends ConsumerState<SignInSheet> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _usernameController = TextEditingController();

  _Step _step = _Step.email;
  bool _busy = false;
  String? _error;
  String _email = '';
  String? _takenName;
  int _cooldown = 0;
  Timer? _ticker;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  void initState() {
    super.initState();
    // A user who closed the sheet at the username step is already signed in.
    final user = _repo.currentUser;
    if (user != null) {
      _email = user.email;
      if (user.hasProfile) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
      } else {
        _step = _Step.username;
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _complete() => widget.onSignedIn();

  String _messageFor(Object error) => switch (error) {
    NetworkException() => SignInSheet.offline,
    RateLimitedException() => SignInSheet.rateLimited,
    InvalidEmailException() => SignInSheet.invalidEmail,
    InvalidCodeException() => SignInSheet.invalidCode,
    UsernameTakenException() => SignInSheet.nameTaken,
    _ => SignInSheet.generic,
  };

  /// Runs [body] with the busy flag set; a thrown error becomes [_error].
  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } on Object catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _cooldown = _resendCooldown.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = SignInSheet.invalidEmail);
      return;
    }
    await _run(() async {
      await _repo.sendEmailCode(email);
      if (!mounted) return;
      _email = email;
      _codeController.clear();
      setState(() => _step = _Step.code);
      _startCooldown();
    });
  }

  Future<void> _resend() async {
    await _run(() async {
      await _repo.sendEmailCode(_email);
      if (!mounted) return;
      _codeController.clear();
      _startCooldown();
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text;
    if (code.length != _codeLength) return;
    await _run(() async {
      try {
        final user = await _repo.verifyEmailCode(_email, code);
        if (!mounted) return;
        if (user.hasProfile) {
          _complete();
        } else {
          setState(() => _step = _Step.username);
        }
      } on InvalidCodeException {
        _codeController.clear();
        rethrow;
      }
    });
  }

  Future<void> _saveUsername() async {
    final name = _usernameController.text;
    if (!isValidUsername(name)) return;
    await _run(() async {
      try {
        if (!await _repo.usernameAvailable(name)) {
          throw const UsernameTakenException();
        }
        await _repo.createProfile(name);
      } on UsernameTakenException {
        if (mounted) _takenName = name;
        rethrow;
      }
      _complete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: AppColors.cream50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.only(bottom: inset),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _sidePadding,
                AppSpacing.md,
                _sidePadding,
                AppSpacing.xl,
              ),
              child: switch (_step) {
                _Step.email => _emailStep(),
                _Step.code => _codeStep(),
                _Step.username => _usernameStep(),
              },
            ),
          ),
        ),
      ),
    );
  }

  static const _sidePadding = 20.0;
  static const _fieldPadding = 17.0;

  Widget _header({
    required IconData icon,
    required Color tile,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.stone200,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(AppRadii.sheet - 4),
          ),
          child: Icon(icon, size: 32, color: iconColor, fill: 1),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.h2.copyWith(color: AppColors.soil900),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: AppColors.soil600),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppText.overline.copyWith(color: AppColors.soil600),
      ),
    ),
  );

  Widget _errorText(String message) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: AppText.bodySm.copyWith(color: AppColors.soil900),
        ),
      ),
    ),
  );

  Widget _emailStep() {
    final hasText = _emailController.text.trim().isNotEmpty;
    return Column(
      key: const ValueKey('step-email'),
      children: [
        _header(
          icon: widget.reason.icon,
          tile: AppColors.gold100,
          iconColor: AppColors.goldLedge,
          title: widget.reason.title,
          body: SignInSheet.subtitle,
        ),
        _label('EMAIL'),
        GeauxTextField(
          controller: _emailController,
          prefixIcon: Symbols.mail_rounded,
          prefixFilled: true,
          verticalPadding: _fieldPadding,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          hasError: _error != null,
          autofocus: true,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) _errorText(_error!),
        const SizedBox(height: 20),
        GeauxButton(
          label: _busy ? 'Sending…' : 'Send code',
          onPressed: hasText && !_busy ? _sendCode : null,
        ),
        const SizedBox(height: 20),
        GeauxButton(
          label: 'Not now',
          variant: GeauxButtonVariant.text,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _codeStep() {
    final ready = _codeController.text.length == _codeLength;
    return Column(
      key: const ValueKey('step-code'),
      children: [
        _header(
          icon: Symbols.mark_email_read_rounded,
          tile: AppColors.tileSky,
          iconColor: AppColors.tileSkyLedge,
          title: 'Check your email',
          body: 'Enter the 6-digit code we sent to $_email.',
        ),
        _CodeField(
          controller: _codeController,
          hasError: _error != null,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: ready && !_busy ? _verify : null,
        ),
        if (_error != null)
          _errorText(_error!)
        else
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _cooldown > 0
                ? Text(
                    'Resend code in ${_cooldown ~/ 60}:'
                    '${(_cooldown % 60).toString().padLeft(2, '0')}',
                    style: AppText.bodySm.copyWith(color: AppColors.soil600),
                  )
                : GeauxButton(
                    label: 'Resend code',
                    variant: GeauxButtonVariant.text,
                    onPressed: _busy ? null : _resend,
                  ),
          ),
        const SizedBox(height: 20),
        GeauxButton(
          label: _busy ? 'Verifying…' : 'Verify',
          onPressed: ready && !_busy ? _verify : null,
        ),
      ],
    );
  }

  Widget _usernameStep() {
    final name = _usernameController.text;
    final taken = _error == SignInSheet.nameTaken;
    return Column(
      key: const ValueKey('step-username'),
      children: [
        _header(
          icon: Symbols.badge_rounded,
          tile: AppColors.tileSoil,
          iconColor: AppColors.tileSoilLedge,
          title: 'Pick a username',
          body: 'This is how other growers will see you.',
        ),
        _label('USERNAME'),
        GeauxTextField(
          controller: _usernameController,
          prefixIcon: Symbols.alternate_email_rounded,
          verticalPadding: _fieldPadding,
          suffix: taken
              ? const Icon(
                  Symbols.error_rounded,
                  color: AppColors.soil900,
                  fill: 1,
                )
              : null,
          maxLength: usernameMaxLength,
          inputFormatters: [_UsernameFormatter()],
          keyboardType: TextInputType.visiblePassword,
          autofillHints: const [AutofillHints.newUsername],
          textInputAction: TextInputAction.done,
          hasError: _error != null,
          autofocus: true,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) _errorText(_error!),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '3–20 characters: lowercase letters, numbers and _',
              style: AppText.caption.copyWith(color: AppColors.soil600),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GeauxButton(
          label: _busy ? 'Saving…' : 'Continue',
          onPressed: isValidUsername(name) && name != _takenName && !_busy
              ? _saveUsername
              : null,
        ),
      ],
    );
  }
}

/// Lowercases and drops characters the username rule never allows, so the
/// field can only hold letters it could accept.
class _UsernameFormatter extends TextInputFormatter {
  static final _disallowed = RegExp('[^a-z0-9_]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.toLowerCase().replaceAll(_disallowed, '');
    if (cleaned == newValue.text) return newValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

/// Six digit boxes drawn over one invisible [TextField], so paste, the
/// number pad, and autofill all work on a single input.
class _CodeField extends StatefulWidget {
  const _CodeField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  @override
  State<_CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<_CodeField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([widget.controller, _focus]),
            builder: (context, _) {
              final text = widget.controller.text;
              final active = _focus.hasFocus
                  ? text.length.clamp(0, _codeLength - 1)
                  : -1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _codeLength; i++)
                    _DigitBox(
                      digit: i < text.length ? text[i] : '',
                      color: widget.hasError
                          ? AppColors.soil900
                          : i == active
                          ? AppColors.leaf500
                          : AppColors.stone200,
                    ),
                ],
              );
            },
          ),
          Positioned.fill(
            child: Semantics(
              label: '6-digit code',
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                expands: true,
                maxLines: null,
                minLines: null,
                showCursor: false,
                enableInteractiveSelection: false,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_codeLength),
                ],
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                ),
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSubmitted?.call(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({required this.digit, required this.color});

  final String digit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 47,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: color, width: AppBorders.width),
        ),
        child: Text(
          digit,
          style: AppText.h1.copyWith(color: AppColors.soil900),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../application/guide_detail_provider.dart';
import '../data/auth_providers.dart';
import '../data/guide_repository_provider.dart';
import '../domain/report_reason.dart';
import 'sign_in_sheet.dart';

/// Asks the user to sign in when they are not, then opens the report sheet
/// for [guideId]. Dismissing either sheet reports nothing.
Future<void> reportGuide(
  BuildContext context,
  WidgetRef ref, {
  required String guideId,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return requireSignIn(
    context,
    ref,
    reason: SignInAction.report,
    action: () async {
      // The sign-in sheet can outlive the screen behind it.
      if (!context.mounted) return;
      // CM-02 decides whether to offer Report from the signed-out state,
      // where no guide is anyone's own. Signing in as the author from
      // that menu must not land on the author reporting themselves, which
      // RLS allows and which would count toward hiding their own guide.
      if (_isOwnGuide(ref, guideId)) return;
      final sent = await showReportSheet(context, guideId: guideId);
      if (sent) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Thanks. We will review this guide.')),
        );
      }
    },
  );
}

/// Whether the signed-in user wrote [guideId]. False while the guide or
/// the user is still unread: the server is the real guard, this only keeps
/// the app from offering the action.
bool _isOwnGuide(WidgetRef ref, String guideId) {
  final guide = ref.read(guideDetailProvider(guideId)).value;
  final userId = ref.read(authStateProvider).value?.id;
  return guide != null && userId != null && guide.authorId == userId;
}

/// Shows the report sheet. Completes with true once a report was stored.
///
/// plan/07 § Moderation has no frame of its own for this sheet, so it is
/// built from the shared tokens and the CM-04 sheet chrome. The design SME
/// still owes it a Figma frame (#60).
Future<bool> showReportSheet(
  BuildContext context, {
  required String guideId,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) => ReportSheet(
      guideId: guideId,
      onReported: () => Navigator.of(sheetContext).pop(true),
    ),
  );
  return sent ?? false;
}

/// The report sheet: pick one reason, add an optional note, send.
class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({
    super.key,
    required this.guideId,
    required this.onReported,
  });

  final String guideId;

  /// Called once the report is stored.
  final VoidCallback onReported;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  static const _sidePadding = 20.0;

  final _note = TextEditingController();
  ReportReason? _reason;
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Sends the chosen reason. Submit is disabled until one is picked, so a
  /// null reason here means the button was not the way in.
  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(guideRepositoryProvider)
          .reportGuide(widget.guideId, reason: reason, note: _note.text);
    } on Object {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = "Couldn't send your report. Try again.";
      });
      return;
    }
    if (!mounted) return;
    widget.onReported();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      // A send already on its way cannot be called back, so the sheet
      // stops taking a swipe or a scrim tap until it lands.
      canPop: !_sending,
      child: _sheet(context, inset),
    );
  }

  Widget _sheet(BuildContext context, double inset) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 20),
                  Text(
                    'Report this guide',
                    textAlign: TextAlign.center,
                    style: AppText.h2.copyWith(color: AppColors.soil900),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tell us what is wrong. A team member reviews reports.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: AppColors.soil600),
                  ),
                  const SizedBox(height: 20),
                  for (final reason in ReportReason.values) ...[
                    GeauxSelectCard(
                      title: reason.label,
                      selected: _reason == reason,
                      onTap: _sending
                          ? () {}
                          : () => setState(() {
                              _reason = reason;
                              _error = null;
                            }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  GeauxTextField(
                    controller: _note,
                    hintText: 'Add a note (optional)',
                    // The field stops at the length guide_reports.note
                    // accepts, so an over-long note cannot be typed.
                    maxLength: maxReportNoteLength,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  GeauxButton(
                    label: 'Send report',
                    icon: Symbols.flag_rounded,
                    onPressed: _reason == null || _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.stone200,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
    );
  }
}

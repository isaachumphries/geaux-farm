import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/http.dart';
import '../../application/guide_editor_provider.dart';
import '../../data/auth_providers.dart';
import '../../data/supabase_guide_repository.dart'
    show GuideWriteRejectedException;
import '../../domain/guide_repository.dart' show GuideNotFoundException;
import '../sign_in_sheet.dart';
import 'basics_step_screen.dart';
import 'editor_copy.dart';
import 'editor_widgets.dart' show editorIconButtonStyle;
import 'materials_step_screen.dart';
import 'plants_step_screen.dart';
import 'preview_step_screen.dart';
import 'steps_step_screen.dart';

final _stepLabels = [for (final step in EditorStep.values) step.label];

/// CM-03a–e: the guide editor. The host of the five steps: it asks a
/// signed-out user to sign in before showing any field, loads an existing
/// guide, and moves between steps. The draft lives in
/// [guideEditorProvider], so a step that is left and opened again starts
/// from what was typed.
///
/// Each visit is a new editing session: opening the editor drops whatever
/// an earlier visit to the same guide left in the provider, so a new guide
/// starts empty and an existing one is read again.
class GuideEditorScreen extends ConsumerStatefulWidget {
  const GuideEditorScreen({super.key, required this.guideId});

  /// The route's `:id`: [newGuideRouteId], or the author's own guide.
  final String guideId;

  @override
  ConsumerState<GuideEditorScreen> createState() => _GuideEditorScreenState();
}

class _GuideEditorScreenState extends ConsumerState<GuideEditorScreen> {
  var _step = EditorStep.basics;

  /// True once the user is signed in with a profile; until then no field of
  /// the editor, and no read of the guide, happens.
  var _signedIn = false;

  @override
  void initState() {
    super.initState();
    final editor = guideEditorProvider(widget.guideId);
    // A write in flight owns the state it will land in: leave that alone.
    if (ref.exists(editor) && !ref.read(editor).saving) ref.invalidate(editor);
    WidgetsBinding.instance.addPostFrameCallback((_) => _requireSignIn());
  }

  /// Opens the editor for a signed-in user. Otherwise CM-04 comes first,
  /// and closing it without signing in closes the editor too.
  Future<void> _requireSignIn() async {
    var signedIn = false;
    await requireSignIn(
      context,
      ref,
      reason: SignInAction.publish,
      action: () => signedIn = true,
    );
    if (!mounted) return;
    if (signedIn) {
      setState(() => _signedIn = true);
    } else {
      _leave();
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/community');
    }
  }

  void _goTo(EditorStep step) {
    // The keyboard belongs to the step being left.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = step);
  }

  /// Back goes to the step before this one, and leaves from the first.
  void _back() {
    if (_step.index == 0) {
      _leave();
    } else {
      _goTo(EditorStep.values[_step.index - 1]);
    }
  }

  void _next() => _goTo(EditorStep.values[_step.index + 1]);

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      // CM-04 is over this screen, or about to be.
      return _frame(
        body: ref.watch(authStateProvider).isLoading
            ? const _Loading()
            : const SizedBox.shrink(),
      );
    }

    final editor = guideEditorProvider(widget.guideId);
    final (loading, loadError, writeError) = ref.watch(
      editor.select(
        (state) => (state.loading, state.loadError, state.writeError),
      ),
    );
    final loaded = !loading && loadError == null;

    final Widget body;
    if (loading) {
      body = const _Loading();
    } else if (loadError != null) {
      body = _LoadFailed(
        error: loadError,
        onRetry: () => ref.read(editor.notifier).load(),
      );
    } else {
      body = switch (_step) {
        EditorStep.basics => BasicsStepScreen(guideId: widget.guideId),
        EditorStep.materials => MaterialsStepScreen(guideId: widget.guideId),
        EditorStep.steps => StepsStepScreen(guideId: widget.guideId),
        EditorStep.plants => PlantsStepScreen(guideId: widget.guideId),
        EditorStep.preview => PreviewStepScreen(
          guideId: widget.guideId,
          onEditStep: _goTo,
        ),
      };
    }

    return _frame(
      step: _step,
      banner: loaded ? _writeBanner(writeError) : null,
      body: body,
      // Preview has the Save draft and Publish buttons instead.
      bottom: loaded && _step != EditorStep.preview
          ? GeauxButton(label: 'Next', onPressed: _next)
          : null,
    );
  }

  /// The screen around [body]: Back, the five dots when [step] is known,
  /// then a [banner], the body and a pinned [bottom] button.
  Widget _frame({
    required Widget body,
    EditorStep? step,
    Widget? banner,
    Widget? bottom,
  }) {
    return PopScope(
      // Back from a later step is a step back, not leaving the editor.
      canPop: _step == EditorStep.basics,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: _back,
                      style: editorIconButtonStyle,
                      icon: const Icon(
                        Symbols.arrow_back_rounded,
                        color: AppColors.soil900,
                      ),
                    ),
                    if (step != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      // Unlike onboarding's, this row has no spacer on the
                      // right: "Materials" needs the room to keep its whole
                      // name under its dot at 360 wide.
                      Expanded(
                        child: GeauxStepProgress(
                          labels: _stepLabels,
                          current: step.index,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (banner != null) ...[
                  banner,
                  const SizedBox(height: AppSpacing.md),
                ],
                Expanded(child: body),
                if (bottom != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  bottom,
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The notice for a write that failed, above the step: Save draft and
/// Publish report on the host's banner so every step shows it. Nothing the
/// author typed is lost. A write the server refused as signed out is
/// Preview's to answer with CM-04, so it gets no banner here.
Widget? _writeBanner(Object? error) {
  if (error == null || isSignInRequired(error)) return null;
  return Semantics(
    liveRegion: true,
    child: GeauxAlertBanner(
      message: switch (error) {
        GuideWriteRejectedException(:final message) => message,
        NetworkException() =>
          "Couldn't save. Check your connection and try again.",
        _ => "Couldn't save. Try again.",
      },
      icon: Symbols.error_rounded,
      accent: AppColors.error,
      tint: AppColors.tilePeach,
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.leaf500),
    );
  }
}

/// Reading the author's guide failed: gone, or worth another try.
class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error is GuideNotFoundException) {
      return const GeauxEmptyState(
        icon: Symbols.menu_book_rounded,
        message: "This guide isn't available.",
      );
    }
    return GeauxEmptyState(
      icon: Symbols.cloud_off_rounded,
      message: "Couldn't load this guide.",
      action: GeauxButton(
        label: 'Retry',
        variant: GeauxButtonVariant.text,
        onPressed: onRetry,
      ),
    );
  }
}

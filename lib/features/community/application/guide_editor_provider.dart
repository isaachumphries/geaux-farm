import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http.dart';
import '../data/guide_repository_provider.dart';
import '../domain/guide_repository.dart';
import '../domain/guide_validation.dart';

/// The editor's state for one guide: the draft the five CM-03 steps write
/// into, the field errors from the last blocked save, and whether a write
/// is in flight.
///
/// A rejected write never clears [draft]: plan/07 § Editor keeps the
/// author's local edits on screen so nothing typed is lost.
class GuideEditorState {
  const GuideEditorState({
    this.draft = const GuideDraft(),
    this.errors = const {},
    this.saving = false,
    this.writeError,
  });

  final GuideDraft draft;

  /// Field name to error code, from the last blocked Save draft or
  /// Publish. Empty while nothing is blocking.
  final Map<String, GuideFieldError> errors;
  final bool saving;

  /// The exception from the last failed write, or null.
  final Object? writeError;

  GuideEditorState copyWith({
    GuideDraft? draft,
    Map<String, GuideFieldError>? errors,
    bool? saving,
    Object? writeError,
    bool clearWriteError = false,
  }) => GuideEditorState(
    draft: draft ?? this.draft,
    errors: errors ?? this.errors,
    saving: saving ?? this.saving,
    writeError: clearWriteError ? null : (writeError ?? this.writeError),
  );
}

/// The editor for one guide, keyed by the route's `:id`. A new guide uses
/// the id `new` (plan/09 § Routes) and holds no draft id until the first
/// save returns one.
final guideEditorProvider =
    NotifierProvider.family<GuideEditorNotifier, GuideEditorState, String>(
      GuideEditorNotifier.new,
    );

/// The route id for a guide that has not been saved yet.
const newGuideRouteId = 'new';

class GuideEditorNotifier extends Notifier<GuideEditorState> {
  GuideEditorNotifier(this.routeId);

  final String routeId;

  @override
  GuideEditorState build() => GuideEditorState(
    draft: GuideDraft(id: routeId == newGuideRouteId ? null : routeId),
  );

  /// Replaces the draft as the author types. Clearing the errors as the
  /// field changes keeps a fixed field from still showing its old error.
  void edit(GuideDraft Function(GuideDraft draft) change) {
    state = state.copyWith(
      draft: change(state.draft),
      errors: const {},
      clearWriteError: true,
    );
  }

  /// Saves the draft if [validateSaveDraft] passes. Returns the guide id,
  /// or null when validation or the write failed.
  Future<String?> saveDraft() =>
      _write(validateSaveDraft, (repo, draft) => repo.saveDraft(draft));

  /// Publishes if [validatePublish] passes. Returns the guide id, or null
  /// when validation or the write failed.
  Future<String?> publish() =>
      _write(validatePublish, (repo, draft) => repo.publishGuide(draft));

  Future<String?> _write(
    Map<String, GuideFieldError> Function(GuideDraft draft) validate,
    Future<String> Function(GuideRepository repo, GuideDraft draft) send,
  ) async {
    if (state.saving) return null;
    final draft = state.draft;
    final errors = validate(draft);
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors, clearWriteError: true);
      return null;
    }
    state = state.copyWith(
      saving: true,
      errors: const {},
      clearWriteError: true,
    );
    try {
      final id = await send(ref.read(guideRepositoryProvider), draft);
      // The first save gets the server-generated id, so later saves update.
      state = state.copyWith(
        draft: state.draft.copyWith(id: id),
        saving: false,
      );
      return id;
    } on Object catch (error) {
      state = state.copyWith(saving: false, writeError: error);
      return null;
    }
  }
}

/// True when [error] means the author must sign in first (CM-04).
bool isSignInRequired(Object? error) => error is AuthRequiredException;

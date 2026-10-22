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
    this.status,
    this.loading = false,
    this.loadError,
    this.errors = const {},
    this.saving = false,
    this.writeError,
  });

  final GuideDraft draft;

  /// The row's status: null until the first save of a new guide.
  final GuideStatus? status;

  /// True while an existing guide is being read for editing.
  final bool loading;

  /// The exception from reading an existing guide, or null.
  final Object? loadError;

  /// Field name to error code, from the last blocked Save draft or
  /// Publish. Empty while nothing is blocking.
  final Map<String, GuideFieldError> errors;
  final bool saving;

  /// The exception from the last failed write, or null.
  final Object? writeError;

  /// A published guide is edited in place (plan/07 § Editor), so saving it
  /// as a draft, which would unpublish it, is not offered.
  bool get canSaveDraft => status != GuideStatus.published;

  GuideEditorState copyWith({
    GuideDraft? draft,
    GuideStatus? status,
    bool? loading,
    Object? loadError,
    Map<String, GuideFieldError>? errors,
    bool? saving,
    Object? writeError,
    bool clearWriteError = false,
  }) => GuideEditorState(
    draft: draft ?? this.draft,
    status: status ?? this.status,
    loading: loading ?? this.loading,
    loadError: loadError ?? this.loadError,
    errors: errors ?? this.errors,
    saving: saving ?? this.saving,
    writeError: clearWriteError ? null : (writeError ?? this.writeError),
  );
}

/// The editor for one guide, keyed by the route's `:id`. A new guide uses
/// the id `new` (plan/09 § Routes) and holds no draft id until the first
/// save returns one; any other id is the author's own guide, read from
/// `guides` when the editor opens.
///
/// Each visit to the editor is its own notifier: it is disposed when the
/// editor closes, so a new guide starts empty and an existing one is read
/// again. A write still in flight when that happens lands on nothing.
final guideEditorProvider = NotifierProvider.autoDispose
    .family<GuideEditorNotifier, GuideEditorState, String>(
      GuideEditorNotifier.new,
    );

/// The route id for a guide that has not been saved yet.
const newGuideRouteId = 'new';

class GuideEditorNotifier extends Notifier<GuideEditorState> {
  GuideEditorNotifier(this.routeId);

  final String routeId;

  @override
  GuideEditorState build() {
    if (routeId == newGuideRouteId) return const GuideEditorState();
    Future.microtask(load);
    return GuideEditorState(draft: GuideDraft(id: routeId), loading: true);
  }

  /// Reads the author's guide [routeId] into the draft. Called once when
  /// the editor opens, and again by Retry after a failed read; a call
  /// while a read is in flight joins it.
  Future<void> load() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void>? _inFlight;

  Future<void> _load() async {
    if (routeId == newGuideRouteId) return;
    state = GuideEditorState(draft: state.draft, loading: true);
    try {
      final guide = await ref.read(guideRepositoryProvider).fetchDraft(routeId);
      if (!ref.mounted) return;
      state = GuideEditorState(draft: guide.draft, status: guide.status);
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = GuideEditorState(draft: state.draft, loadError: error);
    }
  }

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
  /// or null when validation or the write failed, or the guide is
  /// published (see [GuideEditorState.canSaveDraft]).
  Future<String?> saveDraft() async {
    if (!state.canSaveDraft) return null;
    return _write(
      validateSaveDraft,
      (repo, draft) => repo.saveDraft(draft),
      GuideStatus.draft,
    );
  }

  /// Publishes if [validatePublish] passes. Returns the guide id, or null
  /// when validation or the write failed.
  Future<String?> publish() => _write(
    validatePublish,
    (repo, draft) => repo.publishGuide(draft),
    GuideStatus.published,
  );

  Future<String?> _write(
    Map<String, GuideFieldError> Function(GuideDraft draft) validate,
    Future<String> Function(GuideRepository repo, GuideDraft draft) send,
    GuideStatus written,
  ) async {
    if (state.saving || state.loading) return null;
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
      // The editor was left while the write was out: the guide is written,
      // and there is no state left to record it in.
      if (!ref.mounted) return id;
      // The first save gets the server-generated id, so later saves update.
      state = state.copyWith(
        draft: state.draft.copyWith(id: id),
        status: written,
        saving: false,
      );
      return id;
    } on Object catch (error) {
      if (!ref.mounted) return null;
      state = state.copyWith(saving: false, writeError: error);
      return null;
    }
  }
}

/// True when [error] means the author must sign in first (CM-04).
bool isSignInRequired(Object? error) => error is AuthRequiredException;

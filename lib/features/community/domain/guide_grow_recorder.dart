/// Counts a Grow this against the guide: one `guide_grows` row for the
/// signed-in user (plan/07 § Grow this, step 3). A trigger bumps the
/// guide's grow count.
abstract interface class GuideGrowRecorder {
  /// Inserts the row. A row that already exists counts as success.
  ///
  /// Throws `AuthRequiredException` when signed out and `NetworkException`
  /// when the request never got an answer.
  Future<void> recordGrow(String guideId);
}

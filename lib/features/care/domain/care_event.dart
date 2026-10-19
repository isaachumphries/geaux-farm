/// Kind of care logged against a planting.
enum CareEventType {
  water,
  skipWater,
  fertilize,
  prune,
  harvest,
  note;

  /// Text stored in Drift `care_events.type` (snake_case).
  String get stored => this == skipWater ? 'skip_water' : name;

  static CareEventType fromStored(String value) => values.firstWhere(
    (t) => t.stored == value,
    orElse: () => throw FormatException('Unknown care event type', value),
  );
}

/// A logged care action (Drift `care_events`).
class CareEvent {
  const CareEvent({
    required this.id,
    required this.plantingId,
    required this.type,
    required this.at,
    this.note,
    this.photoPath,
  });

  final String id;
  final String plantingId;
  final CareEventType type;
  final DateTime at;
  final String? note;
  final String? photoPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareEvent &&
          other.id == id &&
          other.plantingId == plantingId &&
          other.type == type &&
          other.at == at &&
          other.note == note &&
          other.photoPath == photoPath;

  @override
  int get hashCode =>
      Object.hash(id, plantingId, type, at, note, photoPath);
}

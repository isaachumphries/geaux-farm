import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/care/domain/care_event.dart';
import '../../features/onboarding/domain/availability.dart';
import '../../features/onboarding/domain/user_profile.dart';

/// `user_profile.goals`: a JSON list of [Goal] names.
class GoalsConverter extends TypeConverter<List<Goal>, String> {
  const GoalsConverter();

  @override
  List<Goal> fromSql(String fromDb) => [
    for (final name in jsonDecode(fromDb) as List) Goal.values.byName(name),
  ];

  @override
  String toSql(List<Goal> value) => jsonEncode([for (final g in value) g.name]);
}

/// `user_profile.availability`: a JSON list of 7 bitmasks, Mon..Sun.
class AvailabilityConverter extends TypeConverter<Availability, String> {
  const AvailabilityConverter();

  @override
  Availability fromSql(String fromDb) =>
      Availability(List<int>.from(jsonDecode(fromDb) as List));

  @override
  String toSql(Availability value) => jsonEncode(value.days);
}

/// `care_events.type`: the snake_case text from [CareEventType.stored].
class CareEventTypeConverter extends TypeConverter<CareEventType, String> {
  const CareEventTypeConverter();

  @override
  CareEventType fromSql(String fromDb) => CareEventType.fromStored(fromDb);

  @override
  String toSql(CareEventType value) => value.stored;
}

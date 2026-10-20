import 'care_schedule.dart';
import 'schedule_math.dart';

/// Title on every care reminder.
const careReminderTitle = 'Garden time';

/// Most care reminders kept pending. Weather alerts keep up to three more,
/// so the total is 56 + 3 = 59, below the iOS pending limit of 64.
const careReminderBudget = 56;

/// Plant nicknames listed per verb before the rest collapse into `+N more`.
const _namesShownPerVerb = 3;

/// Calendar days ahead that reminders cover. Matches the care schedule window.
const _horizonDays = 7;

/// Verbs in the order they appear in a body. `other` is not listed.
const _verbs = {
  CareTaskKind.water: 'Water',
  CareTaskKind.fertilize: 'Fertilize',
  CareTaskKind.prune: 'Prune',
  CareTaskKind.harvest: 'Harvest',
};

/// One care reminder: the notification id, the time it fires, its body, and
/// the tap payload that opens the care screen on the slot's date.
class CareReminder {
  const CareReminder({
    required this.id,
    required this.start,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime start;
  final String body;
  final String payload;
}

/// Payload prefix for care reminders. A recompute cancels only ids whose
/// payload carries it, so weather notifications keep their schedule.
const careReminderPayloadPrefix = 'care?date=';

/// True when [payload] belongs to a care reminder.
bool isCareReminderPayload(String? payload) =>
    payload != null && payload.startsWith(careReminderPayloadPrefix);

/// Notification id for a slot: its start in whole UTC minutes since the Unix
/// epoch, mod 2^31. It depends only on the slot, so a restart produces the
/// same ids and a recompute can cancel them.
int careReminderId(DateTime slotStart) =>
    (slotStart.toUtc().millisecondsSinceEpoch ~/ 60000) % (1 << 31);

/// Groups [tasks] into one reminder per slot, earliest first.
///
/// Drops slots that have already started, slots at or beyond the horizon, and
/// slots whose tasks are all `other`. Keeps at most [careReminderBudget]
/// reminders, so the earliest slots win when the cap is hit.
List<CareReminder> planCareReminders({
  required List<ScheduledCareTask> tasks,
  required DateTime now,
}) {
  final horizon = addDays(dayOf(now), _horizonDays);
  final bySlot = <DateTime, List<ScheduledCareTask>>{};
  for (final task in tasks) {
    final start = task.slot.start;
    if (start.isBefore(now) || !start.isBefore(horizon)) continue;
    bySlot.putIfAbsent(start, () => []).add(task);
  }

  final starts = bySlot.keys.toList()..sort();
  final reminders = <CareReminder>[];
  for (final start in starts) {
    final body = _bodyFor(bySlot[start]!);
    if (body == null) continue;
    reminders.add(
      CareReminder(
        id: careReminderId(start),
        start: start,
        body: body,
        payload: '$careReminderPayloadPrefix${_isoDate(dayOf(start))}',
      ),
    );
    if (reminders.length == careReminderBudget) break;
  }
  return reminders;
}

/// Verb-grouped body for one slot, or null when no task has a care verb.
String? _bodyFor(List<ScheduledCareTask> tasks) {
  final parts = <String>[];
  for (final entry in _verbs.entries) {
    final names = [
      for (final task in tasks)
        if (task.kind == entry.key) task.nickname,
    ];
    if (names.isEmpty) continue;
    parts.add(_verbPhrase(entry.value, names));
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

String _verbPhrase(String verb, List<String> names) {
  final shown = names.take(_namesShownPerVerb).join(', ');
  final extra = names.length - _namesShownPerVerb;
  return extra > 0 ? '$verb $shown +$extra more' : '$verb $shown';
}

String _isoDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

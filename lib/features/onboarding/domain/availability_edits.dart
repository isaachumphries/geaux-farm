// Edits to the OB-05 availability value: 7 bitmasks, index 0 = Monday,
// bit `b` = block `b` (plan/02 § OB-05). Pure; every edit returns a new
// list.

const availabilityDays = 7;
const availabilityBlocks = 8;

/// Start label of each 2-hour block.
const blockLabels = [
  '6 AM',
  '8 AM',
  '10 AM',
  '12 PM',
  '2 PM',
  '4 PM',
  '6 PM',
  '8 PM',
];

const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// What a screen reader says for one grid cell (plan/01 § AvailabilityGrid):
/// day, time block, and whether it is selected, e.g. "Monday 6–8 PM,
/// selected". The meridiem is said once when both ends share it.
String availabilityCellLabel(int day, int block, {required bool selected}) {
  final start = 6 + 2 * block;
  final end = start + 2;
  String hour(int h) => '${(h + 11) % 12 + 1}';
  String period(int h) => h < 12 ? 'AM' : 'PM';
  final range = period(start) == period(end)
      ? '${hour(start)}–${hour(end)} ${period(end)}'
      : '${hour(start)} ${period(start)}–${hour(end)} ${period(end)}';
  return '${_dayNames[day]} $range, ${selected ? 'selected' : 'not selected'}';
}

bool isBlockSet(List<int> days, int day, int block) =>
    days[day] & (1 << block) != 0;

List<int> setBlock(List<int> days, int day, int block, bool on) => [
  for (var d = 0; d < availabilityDays; d++)
    d != day
        ? days[d]
        : on
        ? days[d] | (1 << block)
        : days[d] & ~(1 << block),
];

/// The preset chips. Presets OR their cells in; Clear empties the grid.
enum AvailabilityPreset {
  weekdayMornings('Weekday mornings'),
  weekdayEvenings('Weekday evenings'),
  weekendMornings('Weekend mornings'),
  clear('Clear');

  const AvailabilityPreset(this.label);

  final String label;
}

List<int> applyPreset(List<int> days, AvailabilityPreset preset) {
  const weekdays = {0, 1, 2, 3, 4};
  const weekend = {5, 6};
  return switch (preset) {
    AvailabilityPreset.weekdayMornings => _orBlocks(days, weekdays, 1 << 0),
    AvailabilityPreset.weekdayEvenings => _orBlocks(days, weekdays, 1 << 6),
    AvailabilityPreset.weekendMornings => _orBlocks(
      days,
      weekend,
      (1 << 1) | (1 << 2),
    ),
    AvailabilityPreset.clear => List.filled(availabilityDays, 0),
  };
}

List<int> _orBlocks(List<int> days, Set<int> dayIndexes, int mask) => [
  for (var d = 0; d < availabilityDays; d++)
    dayIndexes.contains(d) ? days[d] | mask : days[d],
];

/// "Not sure? Use 8–10 AM every day": block 1 on all 7 days.
List<int> notSureAvailability(List<int> days) => [
  for (final d in days) d | (1 << 1),
];

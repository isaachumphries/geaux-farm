import 'dart:convert';
import 'dart:io';

import 'package:geaux_farm/features/climate/domain/climate_normals.dart';

/// Recorded once from the Open-Meteo archive (30.45, -91.19, 2021–2025).
const archiveFixturePath = 'test/fixtures/archive_baton_rouge_2021_2025.json';

String archiveFixtureBody() => File(archiveFixturePath).readAsStringSync();

/// The fixture's daily rows, parsed here rather than by the app's archive
/// client so the domain tests don't depend on it.
List<DailyClimateRow> archiveFixtureRows() {
  final daily =
      (jsonDecode(archiveFixtureBody()) as Map<String, dynamic>)['daily']
          as Map<String, dynamic>;
  double? at(String key, int i) =>
      ((daily[key] as List)[i] as num?)?.toDouble();
  final time = (daily['time'] as List).cast<String>();
  return [
    for (var i = 0; i < time.length; i++)
      DailyClimateRow(
        date: DateTime.parse(time[i]),
        minF: at('temperature_2m_min', i),
        maxF: at('temperature_2m_max', i),
        precipIn: at('precipitation_sum', i),
        rhPct: at('relative_humidity_2m_mean', i),
        cloudPct: at('cloud_cover_mean', i),
        sunshineS: at('sunshine_duration', i),
      ),
  ];
}

/// Monthly values of the recorded fixture, computed independently of the
/// app code: (month, avgLowF, avgHighF, precipIn, rhPct, cloudPct,
/// sunshineHours).
const recordedMonths = [
  (1, 42.5497, 60.6800, 5.4066, 74.9032, 54.4774, 7.3375),
  (2, 47.2383, 65.9936, 3.9614, 76.9291, 59.2979, 7.7612),
  (3, 53.9794, 72.4065, 5.6032, 74.6323, 56.5419, 8.7844),
  (4, 60.3680, 77.9507, 5.3744, 73.7600, 54.0133, 9.7498),
  (5, 68.5284, 84.8800, 6.3712, 77.0710, 59.0000, 10.5376),
  (6, 74.3107, 90.0893, 4.4206, 77.3600, 53.1733, 11.7968),
  (7, 76.4768, 90.8458, 5.3580, 79.6774, 56.9871, 10.7861),
  (8, 76.5510, 92.2542, 5.2304, 74.2581, 52.3032, 10.5734),
  (9, 71.4633, 87.9380, 5.3420, 72.6400, 39.5267, 10.4380),
  (10, 62.4787, 81.1561, 2.1234, 68.8516, 34.0968, 9.8555),
  (11, 53.4367, 71.0100, 3.5650, 75.4333, 47.3267, 8.1409),
  (12, 49.5103, 66.3742, 5.4276, 79.1097, 55.0452, 7.5939),
];

/// The plan/04 fixture table: (month, avgLowF, avgHighF, meanF, precipIn,
/// rhPct). Open-Meteo has revised its archive since the plan was written,
/// so today's recording matches it only within [planTolerance].
const planMonths = [
  (1, 42.9, 60.6, 51.75, 5.41, 75),
  (2, 47.5, 65.9, 56.70, 3.96, 77),
  (3, 54.3, 72.3, 63.30, 5.60, 75),
  (4, 60.6, 77.9, 69.25, 5.37, 74),
  (5, 68.7, 84.8, 76.75, 6.37, 77),
  (6, 74.4, 90.0, 82.20, 4.42, 77),
  (7, 76.6, 90.7, 83.65, 5.36, 80),
  (8, 76.6, 92.1, 84.35, 5.21, 74),
  (9, 71.6, 87.9, 79.75, 5.37, 73),
  (10, 62.6, 81.1, 71.85, 2.12, 69),
  (11, 53.7, 71.0, 62.35, 3.48, 75),
  (12, 49.7, 66.3, 58.00, 5.51, 79),
];

/// How far the recording may drift from [planMonths]: °F, inches, % RH.
const planTolerance = (tempF: 0.5, precipIn: 0.1, rhPct: 1.0);

import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/plant.dart';

/// Bundle key of the curated catalog (plan/03 § Purpose and file location).
const plantsAssetKey = 'assets/plants/plants.json';

/// Reads and parses every record in `assets/plants/plants.json`.
///
/// A record that fails to parse throws a [FormatException] naming its id
/// (see [Plant.fromJson]); a file that is not a JSON array of objects
/// throws a [FormatException] too.
Future<List<Plant>> loadPlants(AssetBundle bundle) async {
  final decoded = jsonDecode(await bundle.loadString(plantsAssetKey));
  if (decoded is! List) {
    throw const FormatException('$plantsAssetKey is not a JSON array');
  }
  return [
    for (final (i, record) in decoded.indexed)
      if (record is Map<String, dynamic>)
        Plant.fromJson(record)
      else
        throw FormatException('$plantsAssetKey entry $i is not an object'),
  ];
}

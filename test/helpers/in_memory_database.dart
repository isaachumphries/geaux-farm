import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:geaux_farm/core/db/app_database.dart';

/// Replaces the on-device database with a fresh in-memory one, so tests do
/// no file I/O.
Override inMemoryDatabaseOverride() => appDatabaseProvider.overrideWith((ref) {
  final db = AppDatabase(NativeDatabase.memory());
  ref.onDispose(db.close);
  return db;
});

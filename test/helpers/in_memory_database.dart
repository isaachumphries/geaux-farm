import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:geaux_farm/core/db/app_database.dart';

/// Replaces the on-device database with a fresh in-memory one, so tests do
/// no file I/O. Streams close synchronously: by default drift closes a
/// cancelled query stream on a timer, which a widget test reports as
/// pending once the screens watching Drift are torn down.
Override inMemoryDatabaseOverride() => appDatabaseProvider.overrideWith((ref) {
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  ref.onDispose(db.close);
  return db;
});

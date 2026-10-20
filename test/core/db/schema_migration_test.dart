import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/core/db/app_database.dart';

import 'generated/schema.dart';

// plan/09 § Drift schema: any schema change bumps schemaVersion with a
// migration step. drift_schemas/ holds one dump per released version and
// generated/ the helpers built from them. Refresh both with:
//   dart run drift_dev schema dump lib/core/db/app_database.dart drift_schemas/
//   dart run drift_dev schema generate drift_schemas/ test/core/db/generated/
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  final latest = GeneratedHelper.versions.last;

  test('schemaVersion has a schema dump and it is the newest', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(latest, db.schemaVersion);
  });

  test('a fresh install creates exactly the dumped schema', () async {
    // Fails when tables.dart changes without a new schemaVersion and dump.
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await verifier.migrateAndValidate(
      fresh,
      fresh.schemaVersion,
      options: const ValidationOptions(validateDropped: true),
    );
  });

  for (final from in GeneratedHelper.versions.where((v) => v < latest)) {
    test('upgrading from v$from reaches the v$latest schema', () async {
      final db = AppDatabase(await verifier.startAt(from));
      addTearDown(db.close);
      await verifier.migrateAndValidate(
        db,
        latest,
        options: const ValidationOptions(validateDropped: true),
      );
    });
  }
}

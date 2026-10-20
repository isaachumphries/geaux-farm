import 'package:flutter_test/flutter_test.dart';

import '../helpers/import_scan.dart';

const _supabaseImportLine =
    "import 'package:supabase_flutter/supabase_flutter.dart';";

void main() {
  group('package:supabase_flutter import rule (AGENTS.md §4)', () {
    test('repo scan: every lib/**/*.dart import is in an allowed path', () {
      final sources = readDartSources('lib');
      expect(sources, isNotEmpty);

      final violations = supabaseImportViolations(sources);
      expect(violations, isEmpty, reason: supabaseViolationMessage(violations));
    });

    test('fixture outside the allowed list fails and its message names it', () {
      const fixture = 'lib/features/garden/presentation/fixture.dart';

      final violations = supabaseImportViolations({
        fixture: _supabaseImportLine,
      });

      expect(violations, [fixture]);
      expect(supabaseViolationMessage(violations), contains(fixture));
    });

    test('allowed paths may import it', () {
      final violations = supabaseImportViolations({
        'lib/main.dart': _supabaseImportLine,
        'lib/core/env.dart': _supabaseImportLine,
        'lib/features/community/data/community_repository.dart':
            _supabaseImportLine,
        'lib/features/local/data/local_repository.dart': _supabaseImportLine,
      });

      expect(violations, isEmpty);
    });

    test('export, double quotes, and prefix look-alikes are flagged', () {
      const exported =
          "export 'package:supabase_flutter/supabase_flutter.dart';";
      const doubleQuoted =
          'import "package:supabase_flutter/supabase_flutter.dart";';

      final violations = supabaseImportViolations({
        'lib/features/garden/data/export_shim.dart': exported,
        'lib/features/recommendations/data/quoted.dart': doubleQuoted,
        'lib/features/community/database/sync.dart': _supabaseImportLine,
      });

      expect(violations, [
        'lib/features/community/database/sync.dart',
        'lib/features/garden/data/export_shim.dart',
        'lib/features/recommendations/data/quoted.dart',
      ]);
    });

    test('comments and non-import mentions are not flagged', () {
      final violations = supabaseImportViolations({
        'lib/features/garden/presentation/notes.dart':
            "// import 'package:supabase_flutter/supabase_flutter.dart';\n"
            "const name = 'package:supabase_flutter/';",
      });

      expect(violations, isEmpty);
    });
  });
}

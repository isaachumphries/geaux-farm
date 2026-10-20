import 'dart:io';

/// Files (or directory prefixes ending in `/`) allowed to import
/// `package:supabase_flutter`. AGENTS.md §4, "Backend portability".
const supabaseAllowedPaths = <String>[
  'lib/main.dart',
  'lib/core/env.dart',
  'lib/features/community/data/',
  'lib/features/local/data/',
];

final _supabaseImport = RegExp(
  r'''^\s*(import|export)\s+['"]package:supabase_flutter/''',
  multiLine: true,
);

bool _isSupabaseAllowed(String path) => supabaseAllowedPaths.any(
  (allowed) =>
      allowed.endsWith('/') ? path.startsWith(allowed) : path == allowed,
);

/// Returns the sorted paths in [sourcesByPath] that import or export
/// `package:supabase_flutter` from outside [supabaseAllowedPaths].
List<String> supabaseImportViolations(Map<String, String> sourcesByPath) {
  final violations =
      sourcesByPath.entries
          .where((entry) => _supabaseImport.hasMatch(entry.value))
          .map((entry) => entry.key)
          .where((path) => !_isSupabaseAllowed(path))
          .toList()
        ..sort();
  return violations;
}

/// Failure message for [violations] that names every offending path.
String supabaseViolationMessage(List<String> violations) =>
    'package:supabase_flutter may only be imported from '
    '${supabaseAllowedPaths.join(', ')}. Offending files:\n'
    '${violations.map((path) => '  $path').join('\n')}';

/// Reads every `.dart` file under [root], keyed by a forward-slash path.
Map<String, String> readDartSources(String root) => {
  for (final entity in Directory(root).listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.dart'))
      entity.path.replaceAll('\\', '/'): entity.readAsStringSync(),
};

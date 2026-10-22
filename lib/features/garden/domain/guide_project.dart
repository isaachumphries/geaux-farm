import 'dart:convert';

import '../../community/domain/guide.dart';

/// One material on a GD-03 checklist: the guide's row as it was when the
/// user tapped Grow this, plus whether they have it (plan/07 § Grow this).
class ProjectMaterial {
  const ProjectMaterial({
    required this.name,
    required this.qty,
    this.estCostUsd,
    this.checked = false,
  });

  factory ProjectMaterial.fromGuide(GuideMaterial m) =>
      ProjectMaterial(name: m.name, qty: m.qty, estCostUsd: m.estCostUsd);

  factory ProjectMaterial.fromJson(Map<String, Object?> json) =>
      ProjectMaterial(
        name: json['name']! as String,
        qty: json['qty']! as String,
        estCostUsd: json['est_cost_usd'] as int?,
        checked: json['checked']! as bool,
      );

  final String name;
  final String qty;
  final int? estCostUsd;
  final bool checked;

  ProjectMaterial withChecked(bool checked) => ProjectMaterial(
    name: name,
    qty: qty,
    estCostUsd: estCostUsd,
    checked: checked,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'qty': qty,
    'est_cost_usd': estCostUsd,
    'checked': checked,
  };
}

/// One step on a GD-03 checklist, snapshotted from the guide.
class ProjectStep {
  const ProjectStep({
    required this.title,
    required this.body,
    this.done = false,
  });

  factory ProjectStep.fromGuide(GuideStep s) =>
      ProjectStep(title: s.title, body: s.body);

  factory ProjectStep.fromJson(Map<String, Object?> json) => ProjectStep(
    title: json['title']! as String,
    body: json['body']! as String,
    done: json['done']! as bool,
  );

  final String title;
  final String body;
  final bool done;

  ProjectStep withDone(bool done) =>
      ProjectStep(title: title, body: body, done: done);

  Map<String, Object?> toJson() => {'title': title, 'body': body, 'done': done};
}

/// A `guide_projects` row: a community guide copied into My Garden.
class GuideProject {
  const GuideProject({
    required this.id,
    required this.guideId,
    required this.title,
    this.coverUrl,
    required this.materials,
    required this.steps,
    required this.createdAt,
  });

  final String id;
  final String guideId;
  final String title;
  final String? coverUrl;
  final List<ProjectMaterial> materials;
  final List<ProjectStep> steps;
  final DateTime createdAt;
}

String encodeMaterials(List<ProjectMaterial> materials) =>
    jsonEncode([for (final m in materials) m.toJson()]);

List<ProjectMaterial> decodeMaterials(String json) => [
  for (final m in jsonDecode(json) as List<Object?>)
    ProjectMaterial.fromJson(m! as Map<String, Object?>),
];

String encodeSteps(List<ProjectStep> steps) =>
    jsonEncode([for (final s in steps) s.toJson()]);

List<ProjectStep> decodeSteps(String json) => [
  for (final s in jsonDecode(json) as List<Object?>)
    ProjectStep.fromJson(s! as Map<String, Object?>),
];

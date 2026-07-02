class Milestone {
  Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    this.projectName,
    this.description,
    this.parentMilestoneId,
    this.status = 'open',
    this.plannedYear,
    this.plannedQuarter,
    this.position = 0,
    this.inFocus = false,
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String title;

  /// Denormalisierter Projektname für die Roadmap-Ansicht.
  final String? projectName;
  final String? description;

  /// Parent Milestone (für hierarchische Struktur)
  final String? parentMilestoneId;

  /// open | done
  final String status;
  final int? plannedYear;

  /// 1–4
  final int? plannedQuarter;

  /// Position for custom ordering
  final int position;

  /// In focus/starred status
  final bool inFocus;
  final DateTime? createdAt;

  bool get isDone => status == 'done';

  Milestone withStatus(String s) => Milestone(
        id: id,
        projectId: projectId,
        title: title,
        projectName: projectName,
        description: description,
        parentMilestoneId: parentMilestoneId,
        status: s,
        plannedYear: plannedYear,
        plannedQuarter: plannedQuarter,
        position: position,
        inFocus: inFocus,
        createdAt: createdAt,
      );

  factory Milestone.fromMap(Map<String, dynamic> map,
      {String? projectName}) {
    return Milestone(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      title: (map['title'] ?? '') as String,
      projectName:
          projectName ?? (map['projects'] as Map?)?['name'] as String?,
      description: map['description'] as String?,
      parentMilestoneId: map['parent_milestone_id'] as String?,
      status: (map['status'] ?? 'open') as String,
      plannedYear: map['planned_year'] as int?,
      plannedQuarter: map['planned_quarter'] as int?,
      position: (map['position'] ?? 0) as int,
      inFocus: (map['in_focus'] ?? false) as bool,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }
}

/// Repräsentiert eine Zeile aus der `projects`-Tabelle.
class Project {
  Project({
    required this.id,
    required this.name,
    this.icon,
    this.status,
    this.size,
    this.goal,
    this.notes,
    this.shortCode,
    this.plannedYear,
    this.plannedQuarter,
    this.priority,
    this.position = 0,
  });

  final String id;
  final String name;
  final String? icon;

  /// active | done | backlog
  final String? status;

  /// S | M | L
  final String? size;
  final String? goal;
  final String? notes;
  final String? shortCode;
  final int? plannedYear;

  /// 1–4
  final int? plannedQuarter;

  /// high | medium | low
  final String? priority;

  /// Position for custom ordering
  final int position;

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      icon: map['icon'] as String?,
      status: map['status'] as String?,
      size: map['size'] as String?,
      goal: map['goal'] as String?,
      notes: map['notes'] as String?,
      shortCode: map['short_code'] as String?,
      plannedYear: map['planned_year'] as int?,
      plannedQuarter: map['planned_quarter'] as int?,
      priority: map['priority'] as String?,
      position: (map['position'] ?? 0) as int,
    );
  }
}

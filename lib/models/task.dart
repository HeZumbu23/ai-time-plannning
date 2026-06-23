/// Repräsentiert eine Zeile aus der `tasks`-Tabelle.
class Task {
  Task({
    required this.id,
    required this.title,
    required this.status,
    this.context,
    this.size,
    this.nextAction = false,
    this.plannedWeek,
    this.plannedDay,
    this.deadlineDate,
    this.notes,
    this.projectId,
    this.project,
    this.costType,
    this.labels = const [],
    this.dependsOn,
    this.doneAt,
    this.createdAt,
  });

  final String id;
  final String title;

  /// open | done | backlog | blocked
  final String status;

  /// büro | stadt | samstag | sonntag | flexibel
  final String? context;

  /// S | M | L
  final String? size;
  final bool nextAction;
  final int? plannedWeek;
  final DateTime? plannedDay;
  final DateTime? deadlineDate;
  final String? notes;
  final String? projectId;
  final String? project;
  final String? costType;
  final List<String> labels;
  final int? dependsOn;
  final DateTime? doneAt;
  final DateTime? createdAt;

  bool get isDone => status == 'done';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      status: (map['status'] ?? 'open') as String,
      context: map['context'] as String?,
      size: map['size'] as String?,
      nextAction: (map['next_action'] ?? false) as bool,
      plannedWeek: map['planned_week'] as int?,
      plannedDay: _parseDate(map['planned_day']),
      deadlineDate: _parseDate(map['deadline_date']),
      notes: map['notes'] as String?,
      projectId: map['project_id'] as String?,
      project: map['project'] as String?,
      costType: map['cost_type'] as String?,
      labels: (map['labels'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      dependsOn: map['depends_on'] as int?,
      doneAt: _parseDate(map['done_at']),
      createdAt: _parseDate(map['created_at']),
    );
  }
}

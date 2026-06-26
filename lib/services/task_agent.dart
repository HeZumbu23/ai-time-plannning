import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Stellt die Tools bereit, mit denen Claude die Tasks in Supabase lesen und
/// ändern kann, und führt sie aus.
class TaskAgent {
  final SupabaseClient _client = Supabase.instance.client;

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int isoWeek(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final dayOfYear = d.difference(DateTime.utc(d.year, 1, 1)).inDays + 1;
    var week = ((dayOfYear - d.weekday + 10) / 7).floor();
    if (week < 1) {
      week = isoWeek(DateTime.utc(d.year - 1, 12, 31));
    } else if (week > 52) {
      final dec31 = DateTime.utc(d.year, 12, 31).weekday;
      if (week == 53 && dec31 < 4) week = 1;
    }
    return week;
  }

  /// JSON-Schemas der Tools für die Anthropic-API.
  List<Map<String, dynamic>> toolDefinitions() => [
        {
          'name': 'find_tasks',
          'description':
              'Sucht Tasks. Nutze scope für Zeitraum, optional project/status/text-Filter. '
                  'Gibt id, title und Attribute zurück. Verwende die zurückgegebene id für Updates.',
          'input_schema': {
            'type': 'object',
            'properties': {
              'scope': {
                'type': 'string',
                'enum': ['today', 'week', 'backlog', 'all'],
                'description':
                    'today = heute geplant, week = aktuelle KW, backlog = ohne Tag, all = alles',
              },
              'project': {'type': 'string', 'description': 'Projektname (optional)'},
              'status': {
                'type': 'string',
                'enum': ['open', 'done', 'backlog', 'blocked'],
              },
              'text': {'type': 'string', 'description': 'Titel enthält diesen Text'},
              'include_done': {'type': 'boolean'},
            },
          },
        },
        {
          'name': 'create_task',
          'description': 'Legt einen neuen Task an. Nur title ist Pflicht.',
          'input_schema': {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
              'planned_day': {'type': 'string', 'description': 'YYYY-MM-DD'},
              'planned_week': {'type': 'integer'},
              'context': {
                'type': 'string',
                'enum': ['büro', 'stadt', 'samstag', 'sonntag', 'flexibel'],
              },
              'size': {'type': 'string', 'enum': ['S', 'M', 'L']},
              'next_action': {'type': 'boolean'},
              'project': {'type': 'string', 'description': 'Projektname'},
              'deadline_date': {'type': 'string', 'description': 'YYYY-MM-DD'},
              'notes': {'type': 'string'},
            },
            'required': ['title'],
          },
        },
        {
          'name': 'update_task',
          'description':
              'Ändert Felder eines Tasks. id ist Pflicht. Nur angegebene Felder werden geändert.',
          'input_schema': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string'},
              'title': {'type': 'string'},
              'status': {
                'type': 'string',
                'enum': ['open', 'done', 'backlog', 'blocked'],
              },
              'context': {
                'type': 'string',
                'enum': ['büro', 'stadt', 'samstag', 'sonntag', 'flexibel'],
              },
              'size': {'type': 'string', 'enum': ['S', 'M', 'L']},
              'next_action': {'type': 'boolean'},
              'planned_day': {'type': 'string', 'description': 'YYYY-MM-DD oder leer zum Entfernen'},
              'planned_week': {'type': 'integer'},
              'deadline_date': {'type': 'string'},
              'notes': {'type': 'string'},
              'project': {'type': 'string', 'description': 'Projektname'},
            },
            'required': ['id'],
          },
        },
        {
          'name': 'complete_task',
          'description': 'Markiert einen Task als erledigt (status=done).',
          'input_schema': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string'},
            },
            'required': ['id'],
          },
        },
        {
          'name': 'list_projects',
          'description': 'Listet alle Projekte mit id und Name.',
          'input_schema': {'type': 'object', 'properties': {}},
        },
      ];

  /// Führt einen Tool-Aufruf aus und gibt das Ergebnis als JSON-String zurück.
  Future<String> execute(String name, Map<String, dynamic> input) async {
    switch (name) {
      case 'find_tasks':
        return _findTasks(input);
      case 'create_task':
        return _createTask(input);
      case 'update_task':
        return _updateTask(input);
      case 'complete_task':
        return _updateTask({'id': input['id'], 'status': 'done'});
      case 'list_projects':
        return _listProjects();
      default:
        return jsonEncode({'error': 'Unbekanntes Tool: $name'});
    }
  }

  Future<Map<String, String>> _projectNameToId() async {
    final rows = await _client.from('projects').select('id,name');
    return {
      for (final r in rows as List)
        (r['name'] as String).toLowerCase(): r['id'] as String,
    };
  }

  Future<Map<String, String>> _projectIdToName() async {
    final rows = await _client.from('projects').select('id,name');
    return {for (final r in rows as List) r['id'] as String: r['name'] as String};
  }

  Future<String?> _resolveProject(String? name) async {
    if (name == null || name.isEmpty) return null;
    final map = await _projectNameToId();
    return map[name.toLowerCase()];
  }

  Future<String> _findTasks(Map<String, dynamic> input) async {
    const cols =
        'id,title,status,context,size,planned_day,planned_week,next_action,deadline_date,project_id';
    dynamic q = _client.from('tasks').select(cols);

    final scope = (input['scope'] as String?) ?? 'all';
    final now = DateTime.now();
    if (scope == 'today') {
      q = q.eq('planned_day', _dateOnly(now));
    } else if (scope == 'week') {
      q = q.eq('planned_week', isoWeek(now));
    } else if (scope == 'backlog') {
      q = q.isFilter('planned_day', null).inFilter(
          'status', ['open', 'backlog', 'blocked']);
    }

    if (input['status'] != null) q = q.eq('status', input['status']);
    final pid = await _resolveProject(input['project'] as String?);
    if (pid != null) q = q.eq('project_id', pid);
    if (input['text'] != null && (input['text'] as String).isNotEmpty) {
      q = q.ilike('title', '%${input['text']}%');
    }
    final includeDone = input['include_done'] == true;
    if (!includeDone && scope != 'backlog') q = q.neq('status', 'done');

    final rows = (await q.limit(60)) as List;
    final idToName = await _projectIdToName();
    final result = rows.map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      final p = m['project_id'];
      m['project'] = p == null ? null : idToName[p];
      return m;
    }).toList();
    return jsonEncode({'count': result.length, 'tasks': result});
  }

  Future<String> _createTask(Map<String, dynamic> input) async {
    final payload = <String, dynamic>{'title': input['title']};
    for (final k in ['planned_day', 'planned_week', 'context', 'size',
      'next_action', 'deadline_date', 'notes']) {
      if (input.containsKey(k) && input[k] != null) payload[k] = input[k];
    }
    final pid = await _resolveProject(input['project'] as String?);
    if (pid != null) payload['project_id'] = pid;

    final row = await _client.from('tasks').insert(payload).select('id,title').single();
    return jsonEncode({'created': row});
  }

  Future<String> _updateTask(Map<String, dynamic> input) async {
    final id = input['id'] as String?;
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': 'id fehlt'});
    }
    final patch = <String, dynamic>{};
    for (final k in ['title', 'status', 'context', 'size', 'next_action',
      'planned_day', 'planned_week', 'deadline_date', 'notes']) {
      if (input.containsKey(k)) {
        final v = input[k];
        // Leerer String bei Datums-/Textfeldern = entfernen.
        patch[k] = (v is String && v.isEmpty) ? null : v;
      }
    }
    if (input.containsKey('project')) {
      patch['project_id'] = await _resolveProject(input['project'] as String?);
    }
    if (patch['status'] == 'done') {
      patch['done_at'] = DateTime.now().toIso8601String();
    } else if (patch.containsKey('status')) {
      patch['done_at'] = null;
    }
    await _client.from('tasks').update(patch).eq('id', id);
    return jsonEncode({'updated': id, 'fields': patch.keys.toList()});
  }

  Future<String> _listProjects() async {
    final rows = await _client.from('projects').select('id,name,status');
    return jsonEncode({'projects': rows});
  }
}

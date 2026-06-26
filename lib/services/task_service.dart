import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';

/// Datenzugriff auf die `tasks`-Tabelle.
class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  static String _dateOnly(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Erledigte Tasks ans Ende schieben; Reihenfolge innerhalb der Gruppen
  /// (offen / erledigt) bleibt erhalten.
  static List<Task> _doneLast(List<Task> tasks) {
    final open = tasks.where((t) => !t.isDone).toList();
    final done = tasks.where((t) => t.isDone).toList();
    return [...open, ...done];
  }

  /// Tasks für ein bestimmtes Datum (planned_day = day).
  /// Erledigte bleiben sichtbar (durchgestrichen, ans Ende sortiert).
  Future<List<Task>> tasksForDay(DateTime day) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('planned_day', _dateOnly(day))
        .order('next_action', ascending: false)
        .order('size');
    return _doneLast(rows.map<Task>((r) => Task.fromMap(r)).toList());
  }

  /// Offene Next Actions (next_action = true), unabhängig vom Tag.
  Future<List<Task>> nextActions() async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('next_action', true)
        .neq('status', 'done')
        .order('size');
    return rows.map<Task>((r) => Task.fromMap(r)).toList();
  }

  /// Tasks einer Kalenderwoche (planned_week).
  /// Erledigte bleiben sichtbar (durchgestrichen, ans Ende sortiert).
  Future<List<Task>> tasksForWeek(int week) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('planned_week', week)
        .order('planned_day', nullsFirst: false)
        .order('size');
    return _doneLast(rows.map<Task>((r) => Task.fromMap(r)).toList());
  }

  /// Backlog: alles Offene ohne konkrete Tagesplanung.
  Future<List<Task>> backlog() async {
    final rows = await _client
        .from('tasks')
        .select()
        .inFilter('status', ['open', 'backlog', 'blocked'])
        .isFilter('planned_day', null)
        .order('next_action', ascending: false)
        .order('created_at', ascending: false);
    return rows.map<Task>((r) => Task.fromMap(r)).toList();
  }

  /// Tasks eines Projekts.
  Future<List<Task>> tasksForProject(String projectId) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('status')
        .order('size');
    return rows.map<Task>((r) => Task.fromMap(r)).toList();
  }

  /// Status setzen (z.B. als erledigt markieren).
  Future<void> setStatus(String id, String status) async {
    final patch = <String, dynamic>{'status': status};
    patch['done_at'] = status == 'done' ? DateTime.now().toIso8601String() : null;
    await _client.from('tasks').update(patch).eq('id', id);
  }

  Future<void> markDone(String id) => setStatus(id, 'done');

  Future<void> reopen(String id) => setStatus(id, 'open');

  /// Next-Action-Flag umschalten.
  Future<void> setNextAction(String id, bool value) async {
    await _client.from('tasks').update({'next_action': value}).eq('id', id);
  }
}

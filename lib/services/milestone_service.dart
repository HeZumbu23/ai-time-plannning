import 'package:supabase/supabase.dart';

import '../config/supabase_client.dart';
import '../models/milestone.dart';

class MilestoneService {
  SupabaseClient get _client => supabaseClient;

  /// Alle Milestones mit Projektnamen (für Roadmap).
  Future<List<Milestone>> all() async {
    final rows = await _client
        .from('milestones')
        .select('*, projects(name)')
        .order('planned_year', nullsFirst: true)
        .order('planned_quarter', nullsFirst: true)
        .order('created_at');
    return rows
        .map<Milestone>((r) => Milestone.fromMap(r))
        .toList();
  }

  /// Milestones eines einzelnen Projekts.
  Future<List<Milestone>> forProject(String projectId) async {
    final rows = await _client
        .from('milestones')
        .select()
        .eq('project_id', projectId)
        .order('planned_year', nullsFirst: true)
        .order('planned_quarter', nullsFirst: true)
        .order('created_at');
    return rows.map<Milestone>((r) => Milestone.fromMap(r)).toList();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _client.from('milestones').insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> patch) async {
    await _client.from('milestones').update(patch).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('milestones').delete().eq('id', id);
  }
}

import 'package:supabase/supabase.dart';

import '../config/supabase_client.dart';
import '../models/project.dart';

/// Datenzugriff auf die `projects`-Tabelle.
class ProjectService {
  SupabaseClient get _client => supabaseClient;

  Future<List<Project>> all() async {
    final rows = await _client
        .from('projects')
        .select()
        .order('position')
        .order('created_at');
    return rows.map<Project>((r) => Project.fromMap(r)).toList();
  }

  Future<List<Project>> active() async {
    final rows = await _client
        .from('projects')
        .select()
        .eq('status', 'active')
        .order('position')
        .order('created_at');
    return rows.map<Project>((r) => Project.fromMap(r)).toList();
  }

  Future<void> updateProject(String id, Map<String, dynamic> patch) async {
    await _client.from('projects').update(patch).eq('id', id);
  }

  Future<void> updatePosition(String id, int position) async {
    await _client.from('projects').update({'position': position}).eq('id', id);
  }

  Future<String> createProject(Map<String, dynamic> data) async {
    final result = await _client
        .from('projects')
        .insert(data)
        .select('id')
        .single();
    return result['id'] as String;
  }
}

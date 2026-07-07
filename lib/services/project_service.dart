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
        .order('status', ascending: false)
        .order('name');
    return rows.map<Project>((r) => Project.fromMap(r)).toList();
  }

  Future<List<Project>> active() async {
    final rows = await _client
        .from('projects')
        .select()
        .eq('status', 'active')
        .order('created_at');
    return rows.map<Project>((r) => Project.fromMap(r)).toList();
  }

  Future<void> updateProject(String id, Map<String, dynamic> patch) async {
    await _client.from('projects').update(patch).eq('id', id);
  }

  Future<void> updatePosition(String id, int position) async {
    await _client.from('projects').update({'position': position}).eq('id', id);
  }

  Future<void> toggleInFocus(String id, bool inFocus) async {
    await _client.from('projects').update({'in_focus': inFocus}).eq('id', id);
  }

  Future<String> createProject(Map<String, dynamic> data) async {
    final result = await _client
        .from('projects')
        .insert(data)
        .select('id')
        .single();
    return result['id'] as String;
  }

  Future<void> deleteProject(String id) async {
    await _client.from('projects').delete().eq('id', id);
  }
}

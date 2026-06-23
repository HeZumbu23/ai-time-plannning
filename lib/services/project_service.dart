import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project.dart';

/// Datenzugriff auf die `projects`-Tabelle.
class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Project>> all() async {
    final rows = await _client
        .from('projects')
        .select()
        .order('status')
        .order('name');
    return rows.map<Project>((r) => Project.fromMap(r)).toList();
  }

  Future<List<Project>> active() async {
    final rows = await _client
        .from('projects')
        .select()
        .eq('status', 'active')
        .order('name');
    return rows.map<Project>((r) => Project.fromMap(r)).toList();
  }
}

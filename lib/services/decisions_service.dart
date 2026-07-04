import 'package:supabase/supabase.dart';

import '../config/supabase_client.dart';
import '../models/decision.dart';

class DecisionsService {
  SupabaseClient get _client => supabaseClient;

  /// Fetch all decisions for current user, ordered by newest first
  Future<List<Decision>> all() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('decisions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map<Decision>((r) => Decision.fromMap(r)).toList();
  }

  /// Create a new decision
  Future<Decision> create({
    required String method,
    required String topic,
    required String result,
    required Map<String, dynamic> details,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final row = await _client.from('decisions').insert({
      'user_id': userId,
      'method': method,
      'topic': topic,
      'result': result,
      'details': details,
    }).select().single();

    return Decision.fromMap(row);
  }

  /// Update a decision
  Future<Decision> update(
    String id, {
    required String method,
    required String topic,
    required String result,
    required Map<String, dynamic> details,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final row = await _client
        .from('decisions')
        .update({
          'method': method,
          'topic': topic,
          'result': result,
          'details': details,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

    return Decision.fromMap(row);
  }

  /// Delete a decision
  Future<void> delete(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client
        .from('decisions')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}

import 'package:supabase/supabase.dart';

import '../config/supabase_client.dart';
import '../models/journal_entry.dart';

class JournalService {
  SupabaseClient get _client => supabaseClient;

  /// Get all journal entries for a specific date
  Future<List<JournalEntry>> forDate(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final rows = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at', ascending: true);

    return rows.map<JournalEntry>((r) => JournalEntry.fromMap(r)).toList();
  }

  /// Create a new journal entry
  Future<JournalEntry> create({
    required DateTime date,
    required String type,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final row = await _client
        .from('journal_entries')
        .insert({
          'user_id': userId,
          'date': dateStr,
          'type': type,
          'content': content,
          'is_done': false,
        })
        .select()
        .single();

    return JournalEntry.fromMap(row);
  }

  /// Toggle task done status
  Future<void> toggleDone(String id, bool isDone) async {
    await _client
        .from('journal_entries')
        .update({'is_done': isDone, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  /// Delete an entry
  Future<void> delete(String id) async {
    await _client.from('journal_entries').delete().eq('id', id);
  }

  /// Update entry content
  Future<void> update(String id, String content) async {
    await _client.from('journal_entries').update({
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}

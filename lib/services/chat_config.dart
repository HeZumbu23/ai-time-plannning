import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_client.dart';

/// Chat-Einstellungen: Anthropic-API-Key (serverseitig gespeichert) + Modell (lokal).
/// Der API-Key wird mit dem Benutzeraccount verknüpft gespeichert.
class ChatConfig {
  ChatConfig._();

  static const _kModel = 'anthropic_model';

  /// Auswählbare Modelle (Label -> Model-ID).
  static const models = <String, String>{
    'Claude Opus 4.8 (stärkste)': 'claude-opus-4-8',
    'Claude Sonnet 4.6 (schnell)': 'claude-sonnet-4-6',
    'Claude Haiku 4.5 (günstig)': 'claude-haiku-4-5',
  };
  static const defaultModel = 'claude-opus-4-8';

  static Future<String?> apiKey() async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabaseClient
          .from('profile')
          .select('anthropic_api_key')
          .eq('id', userId)
          .maybeSingle();

      final key = response?['anthropic_api_key'] as String?;
      return (key == null || key.isEmpty) ? null : key;
    } catch (e) {
      return null;
    }
  }

  static Future<void> setApiKey(String key) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await supabaseClient
          .from('profile')
          .update({'anthropic_api_key': key.trim()})
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> model() async {
    final p = await SharedPreferences.getInstance();
    final m = p.getString(_kModel);
    return (m != null && models.containsValue(m)) ? m : defaultModel;
  }

  static Future<void> setModel(String modelId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kModel, modelId);
  }
}

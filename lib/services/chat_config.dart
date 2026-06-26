import 'package:shared_preferences/shared_preferences.dart';

/// Lokale Einstellungen für den Chat: Anthropic-API-Key + gewähltes Modell.
/// Der API-Key ist GEHEIM und wird nur auf dem Gerät gespeichert – niemals
/// im Build/Repo.
class ChatConfig {
  ChatConfig._();

  static const _kKey = 'anthropic_api_key';
  static const _kModel = 'anthropic_model';

  /// Auswählbare Modelle (Label -> Model-ID).
  static const models = <String, String>{
    'Claude Opus 4.8 (stärkste)': 'claude-opus-4-8',
    'Claude Sonnet 4.6 (schnell)': 'claude-sonnet-4-6',
    'Claude Haiku 4.5 (günstig)': 'claude-haiku-4-5',
  };
  static const defaultModel = 'claude-opus-4-8';

  static Future<String?> apiKey() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kKey);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> setApiKey(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kKey, key.trim());
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

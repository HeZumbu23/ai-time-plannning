import 'package:shared_preferences/shared_preferences.dart';

class KeyStorage {
  static const _keyPref = 'supabase_publishable_key';

  static Future<String?> loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPref);
  }

  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPref, key);
  }

  static Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPref);
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SupabaseConfig {
  SupabaseConfig._();

  static String _url = 'https://vnfkkujtkbgkqafbbipj.supabase.co';
  static String _anonKey = '';

  static String get url => _url;
  static String get anonKey => _anonKey;
  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (kIsWeb) {
      await _loadFromJson();
    } else {
      _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
          '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuZmtrdWp0a2Jna3FhZmJiaXBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDEwNjk5NzgsImV4cCI6MTczMjYwNTk3OH0'
          '.t5LjWrLqFB8VT-RNJRU6N6HwHPcLQy5STU1Y-Yj_TGo';
    }
  }

  static Future<void> _loadFromJson() async {
    try {
      final response = await http
          .get(Uri.parse('/config.json'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _url = (data['supabaseUrl'] as String?) ?? _url;
        _anonKey = (data['supabaseAnonKey'] as String?) ?? '';
      }
    } catch (_) {}
  }
}

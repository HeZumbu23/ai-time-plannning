import 'dart:convert';

import 'package:http/http.dart' as http;

/// Minimaler Anthropic-Messages-Client mit Tool-Use-Schleife (kein offizielles
/// Flutter-SDK -> direkter HTTPS-Aufruf an /v1/messages).
class AnthropicClient {
  AnthropicClient({required this.apiKey, required this.model});

  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  final String apiKey;
  final String model;

  /// Führt eine Anfrage inkl. Tool-Schleife aus. [messages] ist die laufende
  /// Historie im API-Format und wird um die Assistant-/Tool-Turns ergänzt.
  /// Gibt den finalen Antworttext zurück.
  Future<String> run({
    required List<Map<String, dynamic>> messages,
    required String system,
    required List<Map<String, dynamic>> tools,
    required Future<String> Function(String name, Map<String, dynamic> input)
        onTool,
    int maxSteps = 8,
  }) async {
    for (var step = 0; step < maxSteps; step++) {
      final resp = await _post(messages, system, tools);
      final content = (resp['content'] as List).cast<dynamic>();
      final stop = resp['stop_reason'];

      // Assistant-Turn (inkl. tool_use-Blöcke) für die Historie übernehmen.
      messages.add({'role': 'assistant', 'content': content});

      if (stop == 'tool_use') {
        final results = <Map<String, dynamic>>[];
        for (final block in content) {
          if (block is Map && block['type'] == 'tool_use') {
            String out;
            try {
              out = await onTool(
                block['name'] as String,
                Map<String, dynamic>.from(block['input'] as Map),
              );
            } catch (e) {
              out = jsonEncode({'error': e.toString()});
            }
            results.add({
              'type': 'tool_result',
              'tool_use_id': block['id'],
              'content': out,
            });
          }
        }
        messages.add({'role': 'user', 'content': results});
        continue;
      }

      // Fertig -> Textblöcke zusammenfassen.
      final text = content
          .whereType<Map>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String)
          .join('\n')
          .trim();
      return text.isEmpty ? '(keine Textantwort)' : text;
    }
    return 'Abbruch: zu viele Tool-Schritte hintereinander.';
  }

  Future<Map<String, dynamic>> _post(
    List<Map<String, dynamic>> messages,
    String system,
    List<Map<String, dynamic>> tools,
  ) async {
    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        // Erlaubt den direkten Aufruf aus dem Browser (Web-Build, CORS).
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 4096,
        'system': system,
        'tools': tools,
        'messages': messages,
      }),
    );
    if (res.statusCode != 200) {
      final body = utf8.decode(res.bodyBytes);
      throw 'Anthropic-API ${res.statusCode}: $body';
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}

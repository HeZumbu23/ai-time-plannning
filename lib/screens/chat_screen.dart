import 'package:flutter/material.dart';

import '../services/anthropic_client.dart';
import '../services/chat_config.dart';
import '../services/task_agent.dart';

class _Msg {
  _Msg(this.role, this.text);
  final String role; // 'user' | 'assistant' | 'error'
  final String text;
}

/// Chat mit Claude. Claude kann über Tools die Tasks in Supabase lesen/ändern.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _agent = TaskAgent();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<_Msg> _display = [];
  // Laufende Historie im Anthropic-API-Format.
  final List<Map<String, dynamic>> _api = [];

  String? _apiKey;
  String _model = ChatConfig.defaultModel;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final key = await ChatConfig.apiKey();
    final model = await ChatConfig.model();
    if (mounted) setState(() {
      _apiKey = key;
      _model = model;
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  static const _weekdays = [
    'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'
  ];

  String _systemPrompt() {
    final now = DateTime.now();
    final wd = _weekdays[now.weekday - 1];
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '''
Du bist der Assistent in einer persönlichen TODO-App. Du hilfst dem Nutzer, seine Aufgaben (Tasks) zu verwalten.
Heute ist $wd, der $date (KW ${TaskAgent.isoWeek(now)}).

Du kannst über die bereitgestellten Tools die Tasks in der Datenbank lesen und ändern:
- find_tasks zum Suchen (scope: today/week/backlog/all),
- create_task zum Anlegen,
- update_task zum Ändern,
- complete_task zum Erledigen,
- list_projects für die Projektliste.

Regeln:
- Antworte auf Deutsch, kurz und klar.
- Hole dir mit find_tasks erst die richtige id, bevor du etwas änderst.
- Erlaubte context-Werte: büro, stadt, samstag, sonntag, flexibel. Größen: S, M, L. Status: open, done, backlog, blocked.
- Datumsangaben wie "heute"/"morgen" in YYYY-MM-DD umrechnen.
- Nach Änderungen kurz bestätigen, was du getan hast.''';
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    if (_apiKey == null) {
      _openSettings(hint: true);
      return;
    }

    setState(() {
      _display.add(_Msg('user', text));
      _api.add({'role': 'user', 'content': text});
      _sending = true;
      _input.clear();
    });
    _scrollDown();

    try {
      final client = AnthropicClient(apiKey: _apiKey!, model: _model);
      final reply = await client.run(
        messages: _api,
        system: _systemPrompt(),
        tools: _agent.toolDefinitions(),
        onTool: _agent.execute,
      );
      if (mounted) setState(() => _display.add(_Msg('assistant', reply)));
    } catch (e) {
      if (mounted) setState(() => _display.add(_Msg('error', '$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _openSettings({bool hint = false}) async {
    final keyCtrl = TextEditingController(text: _apiKey ?? '');
    var model = _model;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Chat-Einstellungen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hint)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Bitte zuerst deinen Anthropic-API-Key eintragen.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Anthropic API Key',
                  hintText: 'sk-ant-...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: model,
                decoration: const InputDecoration(
                    labelText: 'Modell', border: OutlineInputBorder()),
                items: ChatConfig.models.entries
                    .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                    .toList(),
                onChanged: (v) => setLocal(() => model = v ?? model),
              ),
              const SizedBox(height: 8),
              const Text(
                'Der Key wird nur lokal auf dem Gerät gespeichert.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                await ChatConfig.setApiKey(keyCtrl.text);
                await ChatConfig.setModel(model);
                if (mounted) {
                  setState(() {
                    _apiKey = keyCtrl.text.trim().isEmpty ? null : keyCtrl.text.trim();
                    _model = model;
                  });
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelLabel = ChatConfig.models.entries
        .firstWhere((e) => e.value == _model,
            orElse: () => MapEntry(_model, _model))
        .key;

    return Column(
      children: [
        // Kopfzeile: Modell + Einstellungen
        Material(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(modelLabel,
                      style: theme.textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  tooltip: 'API-Key / Modell',
                  icon: const Icon(Icons.settings),
                  onPressed: () => _openSettings(),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _display.isEmpty
              ? _emptyHint(theme)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _display.length,
                  itemBuilder: (context, i) => _bubble(_display[i], theme),
                ),
        ),
        if (_sending)
          const LinearProgressIndicator(minHeight: 2),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'z.B. „Verschiebe Postmappe prüfen auf morgen"',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyHint(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy_outlined, size: 56),
            const SizedBox(height: 16),
            Text('Chat mit Claude', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Sag mir in eigenen Worten, was mit deinen Tasks passieren soll – '
              'z.B. „Was steht heute an?", „Leg einen Task ‚Reifen wechseln‘ für Samstag an" '
              'oder „Hak Gemüse kaufen ab".',
              textAlign: TextAlign.center,
            ),
            if (_apiKey == null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openSettings(hint: true),
                icon: const Icon(Icons.key),
                label: const Text('API-Key eintragen'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Msg m, ThemeData theme) {
    final isUser = m.role == 'user';
    final isError = m.role == 'error';
    final color = isError
        ? theme.colorScheme.errorContainer
        : isUser
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SelectableText(
          isError ? '⚠️ ${m.text}' : m.text,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

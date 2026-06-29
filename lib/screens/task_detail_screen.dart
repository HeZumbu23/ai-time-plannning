import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';

/// Detail- und Bearbeitungsseite für einen einzelnen Task.
/// Pop-Ergebnis `true`, wenn etwas gespeichert wurde (Aufrufer lädt dann neu).
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _service = TaskService();

  late TextEditingController _title;
  late TextEditingController _notes;
  late String _status;
  String? _size;
  String? _context;
  late bool _nextAction;
  DateTime? _plannedDay;
  DateTime? _deadline;

  bool _saving = false;
  bool _changed = false;
  String? _daySection;

  static const _statuses = ['open', 'done', 'backlog', 'blocked'];
  static const _sizes = ['S', 'M', 'L'];
  static const _contexts = ['büro', 'stadt', 'samstag', 'sonntag', 'flexibel'];
  static const _daySections = ['vormittag', 'nachmittag', 'abend'];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t.title);
    _notes = TextEditingController(text: t.notes ?? '');
    _status = _statuses.contains(t.status) ? t.status : 'open';
    _size = t.size;
    _context = t.context;
    _nextAction = t.nextAction;
    _plannedDay = t.plannedDay;
    _deadline = t.deadlineDate;
    _daySection = t.daySection;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _markChanged() => setState(() => _changed = true);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final patch = <String, dynamic>{
        'title': _title.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'status': _status,
        'size': _size,
        'context': _context,
        'next_action': _nextAction,
        'planned_day': _plannedDay == null ? null : _fmt(_plannedDay!),
        'deadline_date': _deadline == null ? null : _fmt(_deadline!),
        'done_at': _status == 'done' ? DateTime.now().toIso8601String() : null,
        'day_section': _daySection,
      };
      await _service.updateFields(widget.task.id, patch);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      onPicked(picked);
      _markChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task bearbeiten'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _changed ? _save : null,
              child: const Text('Speichern'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Titel', border: OutlineInputBorder()),
            maxLines: null,
            onChanged: (_) => _markChanged(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
                labelText: 'Status', border: OutlineInputBorder()),
            items: _statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
              _markChanged();
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            value: _daySection,
            decoration: const InputDecoration(
                labelText: 'Tagesabschnitt', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ..._daySections.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s[0].toUpperCase() + s.substring(1)),
                  )),
            ],
            onChanged: (v) {
              setState(() => _daySection = v);
              _markChanged();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _size,
                  decoration: const InputDecoration(
                      labelText: 'Größe', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ..._sizes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) {
                    setState(() => _size = v);
                    _markChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _context,
                  decoration: const InputDecoration(
                      labelText: 'Kontext', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ..._contexts
                        .map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) {
                    setState(() => _context = v);
                    _markChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Next Action'),
            value: _nextAction,
            onChanged: (v) {
              setState(() => _nextAction = v);
              _markChanged();
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Geplant für'),
            subtitle: Text(_plannedDay == null ? 'nicht gesetzt' : _fmt(_plannedDay!)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_plannedDay != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _plannedDay = null);
                      _markChanged();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(
                    current: _plannedDay,
                    onPicked: (d) => setState(() => _plannedDay = d),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Deadline'),
            subtitle: Text(_deadline == null ? 'nicht gesetzt' : _fmt(_deadline!)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_deadline != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _deadline = null);
                      _markChanged();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(
                    current: _deadline,
                    onPicked: (d) => setState(() => _deadline = d),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
                labelText: 'Notizen', border: OutlineInputBorder()),
            minLines: 3,
            maxLines: 8,
            onChanged: (_) => _markChanged(),
          ),
        ],
      ),
    );
  }
}

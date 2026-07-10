import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../services/journal_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _service = JournalService();
  late DateTime _selectedDate;
  late Future<List<JournalEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _entriesFuture = _service.forDate(_selectedDate);
  }

  Future<void> _refresh() async {
    setState(() => _entriesFuture = _service.forDate(_selectedDate));
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _entriesFuture = _service.forDate(_selectedDate);
    });
  }

  Future<void> _addEntry(BulletType type) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text({
          BulletType.task: 'Task hinzufügen',
          BulletType.event: 'Event hinzufügen',
          BulletType.note: 'Notiz hinzufügen',
        }[type]!),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Inhalt...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _service.create(
          date: _selectedDate,
          type: type.name,
          content: result,
        );
        await _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('📔 Journal'),
      ),
      body: Column(
        children: [
          // Date navigation
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
                ),
                Column(
                  children: [
                    Text(
                      _selectedDate.day.toString().padLeft(2, '0'),
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      {
                        1: 'Mo',
                        2: 'Di',
                        3: 'Mi',
                        4: 'Do',
                        5: 'Fr',
                        6: 'Sa',
                        7: 'So',
                      }[_selectedDate.weekday]!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),

          // Entries
          Expanded(
            child: FutureBuilder<List<JournalEntry>>(
              future: _entriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = snapshot.data ?? [];

                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'Noch keine Einträge für diesen Tag',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) => _JournalEntryTile(
                      entry: entries[i],
                      onToggleDone: (entry, isDone) async {
                        await _service.toggleDone(entry.id, isDone);
                        await _refresh();
                      },
                      onDelete: (entry) async {
                        await _service.delete(entry.id);
                        await _refresh();
                      },
                      onEdit: (entry, content) async {
                        await _service.update(entry.id, content);
                        await _refresh();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'note',
            onPressed: () => _addEntry(BulletType.note),
            tooltip: 'Notiz (-)',
            child: const Text('-'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'event',
            onPressed: () => _addEntry(BulletType.event),
            tooltip: 'Event (●)',
            child: const Text('●'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => _addEntry(BulletType.task),
            label: const Text('Task'),
            icon: const Text('•'),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryTile extends StatefulWidget {
  const _JournalEntryTile({
    required this.entry,
    required this.onToggleDone,
    required this.onDelete,
    required this.onEdit,
  });

  final JournalEntry entry;
  final Future<void> Function(JournalEntry, bool) onToggleDone;
  final Future<void> Function(JournalEntry) onDelete;
  final Future<void> Function(JournalEntry, String) onEdit;

  @override
  State<_JournalEntryTile> createState() => _JournalEntryTileState();
}

class _JournalEntryTileState extends State<_JournalEntryTile> {
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _isDone = widget.entry.isDone;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = _isDone;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.entry.type == BulletType.task)
            Checkbox(
              value: isDone,
              onChanged: (v) async {
                if (v != null) {
                  setState(() => _isDone = v);
                  await widget.onToggleDone(widget.entry, v);
                }
              },
            )
          else
            Text(
              widget.entry.bulletSymbol,
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.entry.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? theme.colorScheme.outline : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () async {
              final controller = TextEditingController(text: widget.entry.content);
              final result = await showDialog<String?>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Bearbeiten'),
                  content: TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Abbrechen'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Speichern'),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                await widget.onEdit(widget.entry, result);
              }
            },
            tooltip: 'Bearbeiten',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: () async {
              await widget.onDelete(widget.entry);
            },
            tooltip: 'Löschen',
          ),
        ],
      ),
    );
  }
}

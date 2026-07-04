import 'package:flutter/material.dart';

import '../models/milestone.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/milestone_service.dart';
import '../services/project_service.dart';
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
  final _taskService = TaskService();
  final _milestoneService = MilestoneService();
  final _projectService = ProjectService();

  late TextEditingController _title;
  late TextEditingController _notes;
  late String _status;
  String? _size;
  String? _context;
  String? _milestoneId;
  late bool _nextAction;
  DateTime? _plannedDay;
  DateTime? _deadline;
  late String? _projectId;

  bool _saving = false;
  bool _changed = false;
  late Future<List<Project>> _projectsFuture;
  late Future<List<Milestone>> _milestonesFuture;

  static const _statuses = ['open', 'done', 'blocked'];
  static const _sizes = ['S', 'M', 'L'];
  static const _contexts = ['büro', 'stadt', 'samstag', 'sonntag', 'flexibel'];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t.title);
    _notes = TextEditingController(text: t.notes ?? '');
    _status = _statuses.contains(t.status) ? t.status : 'open';
    _size = t.size;
    _context = t.context;
    _milestoneId = t.milestoneId;
    _nextAction = t.nextAction;
    _plannedDay = t.plannedDay;
    _deadline = t.deadlineDate;
    _projectId = t.projectId;
    _projectsFuture = _projectService.all();
    _milestonesFuture = t.projectId != null
        ? _milestoneService.forProject(t.projectId!)
        : Future.value([]);
  }

  Future<void> _loadMilestonesForProject(String projectId) async {
    setState(() {
      _projectId = projectId;
      _milestoneId = null;
      _milestonesFuture = _milestoneService.forProject(projectId);
      _markChanged();
    });
  }

  Future<void> _createNewProject() async {
    final projectName = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Neues Projekt'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Projektname',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Erstellen'),
            ),
          ],
        );
      },
    );

    if (projectName != null && projectName.isNotEmpty) {
      try {
        final projectId = await ProjectService().createProject({
          'name': projectName,
          'status': 'active',
          'icon': '📁',
        });
        setState(() {
          _projectId = projectId;
          _milestoneId = null;
          _milestonesFuture = _milestoneService.forProject(projectId);
          _projectsFuture = ProjectService().all();
          _markChanged();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Erstellen des Projekts: $e')),
          );
        }
      }
    }
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
      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'status': _status,
        'size': _size,
        'context': _context,
        'milestone_id': _milestoneId,
        'next_action': _nextAction,
        'planned_day': _plannedDay == null ? null : _fmt(_plannedDay!),
        'deadline_date': _deadline == null ? null : _fmt(_deadline!),
        'done_at': _status == 'done' ? DateTime.now().toIso8601String() : null,
      };

      if (widget.task.id.isEmpty) {
        data['project_id'] = _projectId;
        await _taskService.create(data);
      } else {
        data['project_id'] = _projectId;
        await _taskService.updateFields(widget.task.id, data);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Task löschen?'),
        content: const Text('Dieser Task wird dauerhaft gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _saving = true);
      try {
        await _taskService.delete(widget.task.id);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $e')));
          setState(() => _saving = false);
        }
      }
    }
  }

  Future<void> _convertToMilestone() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('In Milestone konvertieren?'),
        content: const Text('Dieser Task wird in einen Milestone umgewandelt und dann gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Konvertieren'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _saving = true);
      try {
        await _milestoneService.create({
          'title': _title.text.trim(),
          'description': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          'project_id': _projectId,
        });
        await _taskService.delete(widget.task.id);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler bei der Konvertierung: $e')),
          );
          setState(() => _saving = false);
        }
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
    final isNewTask = widget.task.id.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task bearbeiten'),
        actions: [
          if (!isNewTask) ...[
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              onPressed: _saving ? null : _convertToMilestone,
              tooltip: 'In Milestone konvertieren',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _saving ? null : _delete,
              tooltip: 'Löschen',
            ),
          ],
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
          FutureBuilder<List<Project>>(
            future: _projectsFuture,
            builder: (context, snapshot) {
              final projects = snapshot.data ?? [];
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _projectId,
                      decoration: const InputDecoration(
                          labelText: 'Projekt', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— Kein Projekt')),
                        ...projects.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            )),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          _loadMilestonesForProject(v);
                        } else {
                          setState(() {
                            _projectId = null;
                            _milestoneId = null;
                            _milestonesFuture = Future.value([]);
                            _markChanged();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _createNewProject,
                    tooltip: 'Neues Projekt',
                  ),
                ],
              );
            },
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
          FutureBuilder<List<Milestone>>(
            future: _milestonesFuture,
            builder: (context, snapshot) {
              final milestones = snapshot.data ?? [];
              return DropdownButtonFormField<String?>(
                value: _milestoneId,
                decoration: const InputDecoration(
                    labelText: 'Milestone', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Unzugeordnet')),
                  ...milestones.map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.title),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _milestoneId = v);
                  _markChanged();
                },
              );
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

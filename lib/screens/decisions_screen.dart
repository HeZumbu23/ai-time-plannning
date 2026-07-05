import 'package:flutter/material.dart';

import '../models/decision.dart';
import '../services/decisions_service.dart';

/// Decision-making tool with multiple methods for clarifying decisions.
class DecisionsScreen extends StatefulWidget {
  const DecisionsScreen({super.key});

  @override
  State<DecisionsScreen> createState() => _DecisionsScreenState();
}

class _DecisionsScreenState extends State<DecisionsScreen> {
  final _service = DecisionsService();
  String? _selectedMethod;
  late Future<List<Decision>> _decisionsFuture;

  @override
  void initState() {
    super.initState();
    _decisionsFuture = _service.all();
  }

  Future<void> _refresh() async {
    setState(() => _decisionsFuture = _service.all());
  }

  Future<void> _saveDecision({
    required String method,
    required String topic,
    required String result,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _service.create(
        method: method,
        topic: topic,
        result: result,
        details: details,
      );

      if (mounted) {
        _refresh();
        setState(() => _selectedMethod = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entscheidung gespeichert! ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

  Future<void> _deleteDecision(String decisionId) async {
    try {
      await _service.delete(decisionId);
      if (mounted) {
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entscheidung gelöscht')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entscheidungshilfe'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.playlist_add), text: 'Neue Entscheidung'),
              Tab(icon: Icon(Icons.history), text: 'Meine Entscheidungen'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNewDecisionTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewDecisionTab() {
    if (_selectedMethod == null) {
      return _buildMethodSelection();
    }

    switch (_selectedMethod) {
      case 'pro_contra':
        return _ProContraMethod(
          onSave: ({
            required method,
            required topic,
            required result,
            required details,
          }) => _saveDecision(method: method, topic: topic, result: result, details: details),
          onBack: () => setState(() => _selectedMethod = null),
        );
      case 'five_hat':
        return _FiveHatMethod(
          onSave: ({
            required method,
            required topic,
            required result,
            required details,
          }) => _saveDecision(method: method, topic: topic, result: result, details: details),
          onBack: () => setState(() => _selectedMethod = null),
        );
      case 'matrix':
        return _MatrixMethod(
          onSave: ({
            required method,
            required topic,
            required result,
            required details,
          }) => _saveDecision(method: method, topic: topic, result: result, details: details),
          onBack: () => setState(() => _selectedMethod = null),
        );
      case 'decision_tree':
        return _DecisionTreeMethod(
          onSave: ({
            required method,
            required topic,
            required result,
            required details,
          }) => _saveDecision(method: method, topic: topic, result: result, details: details),
          onBack: () => setState(() => _selectedMethod = null),
        );
      default:
        return _buildMethodSelection();
    }
  }

  Widget _buildMethodSelection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Wähle eine Methode zur Entscheidungsfindung:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        _MethodCard(
          title: 'Pro & Kontra',
          description: 'Klassische Methode: Sammle Argumente für und gegen eine Option.',
          icon: Icons.balance,
          onTap: () => setState(() => _selectedMethod = 'pro_contra'),
        ),
        const SizedBox(height: 16),
        _MethodCard(
          title: '6 Denkhüte',
          description:
              'Edward de Bono Methode: Betrachte die Entscheidung von 6 verschiedenen Perspektiven.',
          icon: Icons.psychology,
          onTap: () => setState(() => _selectedMethod = 'five_hat'),
        ),
        const SizedBox(height: 16),
        _MethodCard(
          title: 'Entscheidungsmatrix',
          description: 'Gewichte mehrere Optionen nach Kriterien (Wichtigkeit × Dringlichkeit).',
          icon: Icons.grid_3x3,
          onTap: () => setState(() => _selectedMethod = 'matrix'),
        ),
        const SizedBox(height: 16),
        _MethodCard(
          title: 'Entscheidungsbaum',
          description: 'Logisches Verzweigen: Beantworte ja/nein Fragen sequenziell.',
          icon: Icons.account_tree,
          onTap: () => setState(() => _selectedMethod = 'decision_tree'),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<Decision>>(
      future: _decisionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Fehler beim Laden: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          );
        }

        final decisions = snapshot.data ?? [];

        if (decisions.isEmpty) {
          return Center(
            child: Text(
              'Keine Entscheidungen gespeichert. 📝',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: decisions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final decision = decisions[index];
            return _DecisionHistoryTile(
              decision: decision,
              onDelete: () => _deleteDecision(decision.id),
            );
          },
        );
      },
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProContraMethod extends StatefulWidget {
  const _ProContraMethod({
    required this.onSave,
    required this.onBack,
  });

  final Future<void> Function({
    required String method,
    required String topic,
    required String result,
    required Map<String, dynamic> details,
  }) onSave;
  final VoidCallback onBack;

  @override
  State<_ProContraMethod> createState() => _ProContraMethodState();
}

class _ProContraMethodState extends State<_ProContraMethod> {
  final _topicController = TextEditingController();
  final List<String> _pros = [];
  final List<String> _contras = [];
  final _proController = TextEditingController();
  final _contraController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    _proController.dispose();
    _contraController.dispose();
    super.dispose();
  }

  void _save() {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gebe ein Thema ein')),
      );
      return;
    }

    widget.onSave(
      method: 'Pro & Kontra',
      topic: _topicController.text.trim(),
      result: 'Pro: ${_pros.length} | Kontra: ${_contras.length}',
      details: {'pros': _pros, 'contras': _contras},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Worüber möchtest du entscheiden?',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onBack,
              tooltip: 'Zurück',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Argumente DAFÜR:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
        ),
        const SizedBox(height: 8),
        ..._pros.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Chip(
              label: Text(e.value),
              onDeleted: () => setState(() => _pros.removeAt(e.key)),
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _proController,
                decoration: const InputDecoration(
                  labelText: 'Pro hinzufügen...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      _pros.add(v.trim());
                      _proController.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (_proController.text.trim().isNotEmpty) {
                  setState(() {
                    _pros.add(_proController.text.trim());
                    _proController.clear();
                  });
                }
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Argumente DAGEGEN:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
        ),
        const SizedBox(height: 8),
        ..._contras.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Chip(
              label: Text(e.value),
              onDeleted: () => setState(() => _contras.removeAt(e.key)),
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _contraController,
                decoration: const InputDecoration(
                  labelText: 'Kontra hinzufügen...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      _contras.add(v.trim());
                      _contraController.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (_contraController.text.trim().isNotEmpty) {
                  setState(() {
                    _contras.add(_contraController.text.trim());
                    _contraController.clear();
                  });
                }
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: _save,
          child: const Text('Entscheidung speichern'),
        ),
      ],
    );
  }
}

class _FiveHatMethod extends StatefulWidget {
  const _FiveHatMethod({
    required this.onSave,
    required this.onBack,
  });

  final Future<void> Function({
    required String method,
    required String topic,
    required String result,
    required Map<String, dynamic> details,
  }) onSave;
  final VoidCallback onBack;

  @override
  State<_FiveHatMethod> createState() => _FiveHatMethodState();
}

class _FiveHatMethodState extends State<_FiveHatMethod> {
  final _topicController = TextEditingController();
  final Map<String, TextEditingController> _hats = {
    'white': TextEditingController(),
    'red': TextEditingController(),
    'black': TextEditingController(),
    'yellow': TextEditingController(),
    'green': TextEditingController(),
  };

  final Map<String, String> _hatDescriptions = {
    'white': 'Fakten & Daten: Was sind die Fakten?',
    'red': 'Emotionen: Wie fühlt sich das an?',
    'black': 'Kritik: Was könnte schiefgehen?',
    'yellow': 'Optimismus: Was ist das Beste, das passieren kann?',
    'green': 'Kreativität: Welche Alternativen gibt es?',
  };

  final Map<String, Color> _hatColors = {
    'white': const Color(0xFFE0E0E0),
    'red': Colors.red,
    'black': Colors.black,
    'yellow': Colors.amber,
    'green': Colors.green,
  };

  @override
  void dispose() {
    _topicController.dispose();
    for (final controller in _hats.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gebe ein Thema ein')),
      );
      return;
    }

    final details = <String, String>{};
    _hats.forEach((hat, controller) {
      details[hat] = controller.text;
    });

    widget.onSave(
      method: '6 Denkhüte',
      topic: _topicController.text.trim(),
      result: 'Alle Perspektiven analysiert',
      details: details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Worüber möchtest du entscheiden?',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onBack,
              tooltip: 'Zurück',
            ),
          ],
        ),
        const SizedBox(height: 24),
        ..._hats.entries.map((e) {
          final hatColor = _hatColors[e.key]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: hatColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: hatColor.withOpacity(0.3),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _hatDescriptions[e.key]!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: e.value,
                      decoration: const InputDecoration(
                        hintText: 'Deine Gedanken...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: _save,
          child: const Text('Entscheidung speichern'),
        ),
      ],
    );
  }
}

class _MatrixMethod extends StatefulWidget {
  const _MatrixMethod({
    required this.onSave,
    required this.onBack,
  });

  final Future<void> Function({
    required String method,
    required String topic,
    required String result,
    required Map<String, dynamic> details,
  }) onSave;
  final VoidCallback onBack;

  @override
  State<_MatrixMethod> createState() => _MatrixMethodState();
}

class _MatrixMethodState extends State<_MatrixMethod> {
  final _topicController = TextEditingController();
  final _optionsController = TextEditingController();
  final _criteriaController = TextEditingController();
  List<String> _options = [];
  List<String> _criteria = [];
  Map<String, int> _weights = {};
  late Map<String, Map<String, int>> _scores;
  bool _showScoring = false;
  String? _editingCriterion;
  String? _savedDecisionId;
  bool _isSaving = false;

  @override
  void dispose() {
    _topicController.dispose();
    _optionsController.dispose();
    _criteriaController.dispose();
    super.dispose();
  }

  void _initializeScores() {
    _scores = {};
    for (final option in _options) {
      _scores[option] = {};
      for (final criterion in _criteria) {
        _scores[option]![criterion] = 3;
      }
    }
  }

  void _addOption(String option) {
    if (option.trim().isNotEmpty && !_options.contains(option.trim())) {
      setState(() {
        _options.add(option.trim());
        _initializeScores();
        _optionsController.clear();
      });
    }
  }

  void _addCriterion(String criterion) {
    if (criterion.trim().isNotEmpty && !_criteria.contains(criterion.trim())) {
      setState(() {
        _criteria.add(criterion.trim());
        _weights[criterion.trim()] = 1;
        _initializeScores();
        _criteriaController.clear();
      });
    }
  }

  void _removeCriterion(String criterion) {
    setState(() {
      _criteria.remove(criterion);
      _weights.remove(criterion);
      _initializeScores();
    });
  }

  void _editCriterion(String oldName, String newName) {
    if (newName.trim().isNotEmpty && oldName != newName) {
      setState(() {
        final idx = _criteria.indexOf(oldName);
        if (idx >= 0) {
          _criteria[idx] = newName.trim();
          _weights[newName.trim()] = _weights.remove(oldName) ?? 1;
          for (final option in _options) {
            final score = _scores[option]?.remove(oldName);
            if (score != null) {
              _scores[option]![newName.trim()] = score;
            }
          }
        }
        _editingCriterion = null;
      });
    }
  }

  double _calculateScore(String option) {
    double total = 0;
    for (final criterion in _criteria) {
      final score = _scores[option]![criterion] ?? 3;
      final weight = _weights[criterion] ?? 1;
      total += score * weight;
    }
    return total;
  }

  String _calculateResult() {
    String bestOption = _options.first;
    double bestScore = 0;

    for (final option in _options) {
      final score = _calculateScore(option);
      if (score > bestScore) {
        bestScore = score;
        bestOption = option;
      }
    }

    return 'Beste Option: $bestOption (Punkte: ${bestScore.toStringAsFixed(1)})';
  }

  Future<void> _autoSave() async {
    if (_isSaving || _topicController.text.trim().isEmpty || _options.isEmpty || _criteria.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = DecisionsService();
      if (_savedDecisionId == null) {
        final decision = await service.create(
          method: 'Entscheidungsmatrix',
          topic: _topicController.text.trim(),
          result: _calculateResult(),
          details: {
            'options': _options,
            'criteria': _criteria,
            'weights': _weights,
            'scores': _scores,
          },
        );
        setState(() => _savedDecisionId = decision.id);
      } else {
        await service.update(
          _savedDecisionId!,
          method: 'Entscheidungsmatrix',
          topic: _topicController.text.trim(),
          result: _calculateResult(),
          details: {
            'options': _options,
            'criteria': _criteria,
            'weights': _weights,
            'scores': _scores,
          },
        );
      }
      if (mounted) setState(() => _isSaving = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

  Future<void> _finalSave() async {
    await _autoSave();
    if (_savedDecisionId != null && mounted) {
      widget.onSave(
        method: 'Entscheidungsmatrix',
        topic: _topicController.text.trim(),
        result: _calculateResult(),
        details: {
          'options': _options,
          'criteria': _criteria,
          'weights': _weights,
          'scores': _scores,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showScoring) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Worüber möchtest du entscheiden?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onBack,
                tooltip: 'Zurück',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Optionen:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ..._options.map((o) => Chip(
                    label: Text(o),
                    onDeleted: () => setState(() {
                      _options.remove(o);
                      _initializeScores();
                    }),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Option hinzufügen...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: _addOption,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _addOption(_optionsController.text),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Bewertungskriterien (mit Gewichtung):',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._criteria.asMap().entries.map((e) {
            final criterion = e.value;
            final weight = _weights[criterion] ?? 1;
            final isEditing = _editingCriterion == criterion;

            if (isEditing) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Kriterienname',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(text: criterion),
                        onSubmitted: (newName) => _editCriterion(criterion, newName),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: DropdownButton<int>(
                        value: weight,
                        isExpanded: true,
                        items: [1, 2, 3, 5, 10]
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text('$w×'),
                                ))
                            .toList(),
                        onChanged: (w) {
                          if (w != null) {
                            setState(() => _weights[criterion] = w);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () => setState(() => _editingCriterion = null),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Chip(
                      label: Text('$criterion (${weight}×)'),
                      onDeleted: () => _removeCriterion(criterion),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    iconSize: 18,
                    onPressed: () => setState(() => _editingCriterion = criterion),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _criteriaController,
                  decoration: const InputDecoration(
                    labelText: 'Kriterium hinzufügen...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: _addCriterion,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _addCriterion(_criteriaController.text),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          if (_options.isNotEmpty && _criteria.isNotEmpty) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                _initializeScores();
                _autoSave();
                setState(() => _showScoring = true);
              },
              child: const Text('Zur Bewertung fortfahren'),
            ),
          ]
        ],
      );
    }

    final sortedOptions = List<String>.from(_options)
      ..sort((a, b) => _calculateScore(b).compareTo(_calculateScore(a)));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bewertung der Optionen:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Kriterien ändern'),
              onPressed: () => setState(() => _showScoring = false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Option')),
              ..._criteria.map((c) {
                final weight = _weights[c] ?? 1;
                return DataColumn(
                  label: SizedBox(
                    width: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          c,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          'Gewicht: $weight',
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const DataColumn(label: Text('Gesamt')),
            ],
            rows: _options
                .map((option) {
                  final total = _calculateScore(option);
                  return DataRow(
                    cells: [
                      DataCell(SizedBox(
                        width: 100,
                        child: Text(option),
                      )),
                      ..._criteria.map((criterion) {
                        final score = _scores[option]![criterion] ?? 3;
                        return DataCell(
                          DropdownButton<int>(
                            value: score,
                            items: [1, 2, 3, 4, 5]
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v.toString()),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() =>
                                    _scores[option]![criterion] = v);
                              }
                            },
                          ),
                        );
                      }),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            total.toStringAsFixed(0),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                })
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ranking:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...sortedOptions.asMap().entries.map((e) {
          final option = e.value;
          final score = _calculateScore(option);
          final rank = e.key + 1;
          final theme = Theme.of(context);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rank == 1
                    ? Colors.green.withOpacity(0.2)
                    : rank == 2
                        ? Colors.amber.withOpacity(0.2)
                        : theme.colorScheme.surfaceContainer,
                border: Border.all(
                  color: rank == 1
                      ? Colors.green
                      : rank == 2
                          ? Colors.amber
                          : theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$rank. $option',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    score.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                  ),
                ),
              )
            else
              const SizedBox(width: 24),
            FilledButton(
              onPressed: _finalSave,
              child: const Text('Fertig'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DecisionTreeMethod extends StatefulWidget {
  const _DecisionTreeMethod({
    required this.onSave,
    required this.onBack,
  });

  final Future<void> Function({
    required String method,
    required String topic,
    required String result,
    required Map<String, dynamic> details,
  }) onSave;
  final VoidCallback onBack;

  @override
  State<_DecisionTreeMethod> createState() => _DecisionTreeMethodState();
}

class _DecisionTreeMethodState extends State<_DecisionTreeMethod> {
  final _topicController = TextEditingController();
  final List<_TreeNode> _nodes = [_TreeNode(id: '0', question: '', yesChild: null, noChild: null)];
  String? _currentNodeId = '0';
  late TextEditingController _questionController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _updateQuestionController();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  void _updateQuestionController() {
    final currentNode = _currentNodeId != null ? _findNode(_currentNodeId!) : null;
    _questionController.text = currentNode?.question ?? '';
  }

  _TreeNode? _findNode(String id) {
    _TreeNode? findRecursive(_TreeNode node) {
      if (node.id == id) return node;
      if (node.yesChild != null) {
        final found = findRecursive(node.yesChild!);
        if (found != null) return found;
      }
      if (node.noChild != null) {
        final found = findRecursive(node.noChild!);
        if (found != null) return found;
      }
      return null;
    }
    return findRecursive(_nodes.first);
  }

  void _setQuestion(String id, String question) {
    final node = _findNode(id);
    if (node != null) {
      node.question = question;
      setState(() {});
    }
  }

  void _addYesNode(String parentId) {
    final parent = _findNode(parentId);
    if (parent != null) {
      parent.yesChild = _TreeNode(
        id: '${DateTime.now().millisecondsSinceEpoch}_yes',
        question: '',
        yesChild: null,
        noChild: null,
      );
      setState(() {
        _currentNodeId = parent.yesChild!.id;
        _updateQuestionController();
      });
    }
  }

  void _addNoNode(String parentId) {
    final parent = _findNode(parentId);
    if (parent != null) {
      parent.noChild = _TreeNode(
        id: '${DateTime.now().millisecondsSinceEpoch}_no',
        question: '',
        yesChild: null,
        noChild: null,
      );
      setState(() {
        _currentNodeId = parent.noChild!.id;
        _updateQuestionController();
      });
    }
  }

  void _save() {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gebe ein Thema ein')),
      );
      return;
    }

    widget.onSave(
      method: 'Entscheidungsbaum',
      topic: _topicController.text.trim(),
      result: 'Entscheidungsbaum mit ${_countNodes(_nodes.first)} Fragen',
      details: {'tree': _serializeTree(_nodes.first)},
    );
  }

  int _countNodes(_TreeNode node) {
    int count = 1;
    if (node.yesChild != null) count += _countNodes(node.yesChild!);
    if (node.noChild != null) count += _countNodes(node.noChild!);
    return count;
  }

  Map<String, dynamic> _serializeTree(_TreeNode node) {
    return {
      'question': node.question,
      'yes': node.yesChild != null ? _serializeTree(node.yesChild!) : null,
      'no': node.noChild != null ? _serializeTree(node.noChild!) : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentNode = _currentNodeId != null ? _findNode(_currentNodeId!) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Worüber möchtest du entscheiden?',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onBack,
              tooltip: 'Zurück',
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (currentNode != null) ...[
          TextField(
            controller: _questionController,
            onChanged: (v) => _setQuestion(currentNode.id, v),
            decoration: const InputDecoration(
              labelText: 'Frage formulieren...',
              hintText: 'z.B. "Habe ich genug Zeit?"',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
          ),
          const SizedBox(height: 16),
          if (currentNode.question.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _addYesNode(currentNode.id),
                    child: const Text('Ja → Neue Frage'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _addNoNode(currentNode.id),
                    child: const Text('Nein → Neue Frage'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Fragen: ${_countNodes(_nodes.first)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: _save,
          child: const Text('Entscheidung speichern'),
        ),
      ],
    );
  }
}

class _DecisionHistoryTile extends StatefulWidget {
  const _DecisionHistoryTile({
    required this.decision,
    required this.onDelete,
  });

  final Decision decision;
  final VoidCallback onDelete;

  @override
  State<_DecisionHistoryTile> createState() => _DecisionHistoryTileState();
}

class _DecisionHistoryTileState extends State<_DecisionHistoryTile> {
  bool _expanded = false;
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _topicController;
  late TextEditingController _resultController;
  final _service = DecisionsService();

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.decision.topic);
    _resultController = TextEditingController(text: widget.decision.result);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _showHatsEditDialog(BuildContext context, ThemeData theme, Map<String, String> hats, Map<String, String> hatLabels) {
    final hatsLocal = Map<String, String>.from(hats);
    final hatsOrder = ['white', 'red', 'black', 'yellow', 'green'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Denkhüte bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final hat in hatsOrder)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      initialValue: hatsLocal[hat] ?? '',
                      decoration: InputDecoration(
                        labelText: hatLabels[hat],
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (v) => hatsLocal[hat] = v,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _saveChanges(updatedDetails: hatsLocal);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProContraEditDialog(BuildContext context, ThemeData theme, List<String> pros, List<String> contras) {
    final prosLocal = List<String>.from(pros);
    final contrasLocal = List<String>.from(contras);
    final proController = TextEditingController();
    final contraController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Pro & Kontra bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DAFÜR:', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...prosLocal.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Chip(
                    label: Text(e.value),
                    onDeleted: () => setState(() => prosLocal.removeAt(e.key)),
                  ),
                )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: proController,
                        decoration: const InputDecoration(
                          hintText: 'Pro hinzufügen...',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            setState(() {
                              prosLocal.add(v.trim());
                              proController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (proController.text.trim().isNotEmpty) {
                          setState(() {
                            prosLocal.add(proController.text.trim());
                            proController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('DAGEGEN:', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...contrasLocal.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Chip(
                    label: Text(e.value),
                    onDeleted: () => setState(() => contrasLocal.removeAt(e.key)),
                  ),
                )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: contraController,
                        decoration: const InputDecoration(
                          hintText: 'Kontra hinzufügen...',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            setState(() {
                              contrasLocal.add(v.trim());
                              contraController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (contraController.text.trim().isNotEmpty) {
                          setState(() {
                            contrasLocal.add(contraController.text.trim());
                            contraController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _saveChanges(
                  updatedDetails: {
                    'pros': prosLocal,
                    'contras': contrasLocal,
                  },
                );
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges({Map<String, dynamic>? updatedDetails}) async {
    if (!_isSaving) {
      setState(() => _isSaving = true);
      try {
        await _service.update(
          widget.decision.id,
          method: widget.decision.method,
          topic: _topicController.text.trim(),
          result: _resultController.text.trim(),
          details: updatedDetails ?? widget.decision.details,
        );
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gespeichert ✓'), duration: Duration(seconds: 2)),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
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

    if (_isEditing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entscheidung bearbeiten',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Thema',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                onChanged: (_) => _saveChanges(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _resultController,
                decoration: const InputDecoration(
                  labelText: 'Ergebnis',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                onChanged: (_) => _saveChanges(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSaving)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Fertig'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.decision.topic,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.decision.method,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Bearbeiten',
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  tooltip: _expanded ? 'Zusammenklappen' : 'Erweitern',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                  tooltip: 'Löschen',
                )
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.decision.result,
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 16),
              _buildDetailedView(context, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context, ThemeData theme) {
    final decision = widget.decision;

    switch (decision.method) {
      case 'Pro & Kontra':
        final pros = (decision.details['pros'] as List<dynamic>?)?.cast<String>() ?? [];
        final contras = (decision.details['contras'] as List<dynamic>?)?.cast<String>() ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Argumente:',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Bearbeiten'),
                  onPressed: () {
                    _showProContraEditDialog(context, theme, pros, contras);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'DAFÜR:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                ...pros.map((p) => Chip(label: Text(p))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'DAGEGEN:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                ...contras.map((c) => Chip(label: Text(c))),
              ],
            ),
          ],
        );
      case '6 Denkhüte':
        final hats = ['white', 'red', 'black', 'yellow', 'green'];
        final hatLabels = {
          'white': 'Fakten (Weiß)',
          'red': 'Emotionen (Rot)',
          'black': 'Kritik (Schwarz)',
          'yellow': 'Optimismus (Gelb)',
          'green': 'Kreativität (Grün)',
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Denkhüte:',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Bearbeiten'),
                  onPressed: () {
                    _showHatsEditDialog(context, theme, decision.details.cast<String, String>(), hatLabels);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final hat in hats)
              if (decision.details[hat] != null && (decision.details[hat] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hatLabels[hat] ?? hat,
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        decision.details[hat] as String,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
          ],
        );
      case 'Entscheidungsmatrix':
        final options = (decision.details['options'] as List<dynamic>?)?.cast<String>() ?? [];
        final criteria = (decision.details['criteria'] as List<dynamic>?)?.cast<String>() ?? [];
        final weightsRaw = decision.details['weights'] as Map<String, dynamic>? ?? {};
        final weights = weightsRaw.map((k, v) => MapEntry(k, (v as num).toInt()));
        final scoresRaw = decision.details['scores'] as Map<String, dynamic>? ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optionen:',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                ...options.map((o) => Chip(label: Text(o))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Kriterien:',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                ...criteria.map((c) {
                  final weight = weights[c] ?? 1;
                  return Chip(label: Text('$c (${weight}×)'));
                }),
              ],
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}

class _TreeNode {
  final String id;
  String question;
  _TreeNode? yesChild;
  _TreeNode? noChild;

  _TreeNode({
    required this.id,
    required this.question,
    required this.yesChild,
    required this.noChild,
  });
}

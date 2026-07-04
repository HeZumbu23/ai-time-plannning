import 'package:flutter/material.dart';

/// Decision-making tool with multiple methods for clarifying decisions.
class DecisionsScreen extends StatefulWidget {
  const DecisionsScreen({super.key});

  @override
  State<DecisionsScreen> createState() => _DecisionsScreenState();
}

class _DecisionsScreenState extends State<DecisionsScreen> {
  String? _selectedMethod;
  final List<_Decision> _decisions = [];

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
          onSave: _saveDecision,
          onBack: () => setState(() => _selectedMethod = null),
        );
      case 'five_hat':
        return _FiveHatMethod(
          onSave: _saveDecision,
          onBack: () => setState(() => _selectedMethod = null),
        );
      case 'matrix':
        return _MatrixMethod(
          onSave: _saveDecision,
          onBack: () => setState(() => _selectedMethod = null),
        );
      case 'decision_tree':
        return _DecisionTreeMethod(
          onSave: _saveDecision,
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
          icon: Icons.plus_minus,
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
    if (_decisions.isEmpty) {
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
      itemCount: _decisions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final decision = _decisions[_decisions.length - 1 - index];
        return _DecisionHistoryTile(
          decision: decision,
          onDelete: () => setState(() => _decisions.removeAt(_decisions.length - 1 - index)),
        );
      },
    );
  }

  void _saveDecision(_Decision decision) {
    setState(() {
      _decisions.add(decision);
      _selectedMethod = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entscheidung gespeichert! ✓')),
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

  final void Function(_Decision) onSave;
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

    final decision = _Decision(
      method: 'Pro & Kontra',
      topic: _topicController.text.trim(),
      result: 'Pro: ${_pros.length} | Kontra: ${_contras.length}',
      details: {'pros': _pros, 'contras': _contras},
    );

    widget.onSave(decision);
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

  final void Function(_Decision) onSave;
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

    final decision = _Decision(
      method: '6 Denkhüte',
      topic: _topicController.text.trim(),
      result: 'Alle Perspektiven analysiert',
      details: details,
    );

    widget.onSave(decision);
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

  final void Function(_Decision) onSave;
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
  late Map<String, Map<String, int>> _scores;

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
        _initializeScores();
        _criteriaController.clear();
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

    if (_options.isEmpty || _criteria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens eine Option und ein Kriterium erforderlich')),
      );
      return;
    }

    String bestOption = _options.first;
    int bestScore = 0;

    for (final option in _options) {
      int score = 0;
      for (final criterion in _criteria) {
        score += _scores[option]![criterion] ?? 0;
      }
      if (score > bestScore) {
        bestScore = score;
        bestOption = option;
      }
    }

    final decision = _Decision(
      method: 'Entscheidungsmatrix',
      topic: _topicController.text.trim(),
      result: 'Beste Option: $bestOption (Punkte: $bestScore)',
      details: {'options': _options, 'criteria': _criteria, 'scores': _scores},
    );

    widget.onSave(decision);
  }

  @override
  Widget build(BuildContext context) {
    if (_options.isEmpty || _criteria.isEmpty) {
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
          ..._options
              .map((o) => Chip(
                    label: Text(o),
                    onDeleted: () => setState(() {
                      _options.remove(o);
                      _initializeScores();
                    }),
                  ))
              .toList(),
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
            'Bewertungskriterien:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ..._criteria
              .map((c) => Chip(
                    label: Text(c),
                    onDeleted: () => setState(() {
                      _criteria.remove(c);
                      _initializeScores();
                    }),
                  ))
              .toList(),
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
              onPressed: () => setState(() => _initializeScores()),
              child: const Text('Mit Bewertung fortfahren'),
            ),
          ]
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bewerte jede Option (1-5):',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Option/Kriterium')),
              ..._criteria.map((c) => DataColumn(label: SizedBox(
                    width: 60,
                    child: Text(
                      c,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ))),
            ],
            rows: _options
                .map((option) => DataRow(
                      cells: [
                        DataCell(SizedBox(
                          width: 100,
                          child: Text(
                            option,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      ],
                    ))
                .toList(),
          ),
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

class _DecisionTreeMethod extends StatefulWidget {
  const _DecisionTreeMethod({
    required this.onSave,
    required this.onBack,
  });

  final void Function(_Decision) onSave;
  final VoidCallback onBack;

  @override
  State<_DecisionTreeMethod> createState() => _DecisionTreeMethodState();
}

class _DecisionTreeMethodState extends State<_DecisionTreeMethod> {
  final _topicController = TextEditingController();
  final _questionController = TextEditingController();
  final List<_TreeNode> _nodes = [_TreeNode(id: '0', question: '', yesChild: null, noChild: null)];
  String? _currentNodeId = '0';

  @override
  void dispose() {
    _topicController.dispose();
    _questionController.dispose();
    super.dispose();
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
      setState(() => _currentNodeId = parent.yesChild!.id);
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
      setState(() => _currentNodeId = parent.noChild!.id);
    }
  }

  void _save() {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gebe ein Thema ein')),
      );
      return;
    }

    final decision = _Decision(
      method: 'Entscheidungsbaum',
      topic: _topicController.text.trim(),
      result: 'Entscheidungsbaum mit ${_countNodes(_nodes.first)} Fragen',
      details: {'tree': _serializeTree(_nodes.first)},
    );

    widget.onSave(decision);
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

class _DecisionHistoryTile extends StatelessWidget {
  const _DecisionHistoryTile({
    required this.decision,
    required this.onDelete,
  });

  final _Decision decision;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                        decision.topic,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        decision.method,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
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
                decision.result,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Decision {
  final String method;
  final String topic;
  final String result;
  final Map<String, dynamic> details;

  _Decision({
    required this.method,
    required this.topic,
    required this.result,
    required this.details,
  });
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

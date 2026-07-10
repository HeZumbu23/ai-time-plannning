import 'package:intl/intl.dart';

enum BulletType { task, event, note }

class JournalEntry {
  final String id;
  final String userId;
  final DateTime date;
  final BulletType type;
  final String content;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.content,
    this.isDone = false,
    required this.createdAt,
    this.updatedAt,
  });

  String get bulletSymbol {
    switch (type) {
      case BulletType.task:
        return isDone ? '✓' : '•';
      case BulletType.event:
        return '●';
      case BulletType.note:
        return '-';
    }
  }

  String get formattedDate => DateFormat('dd.MM.yyyy').format(date);

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: DateTime.parse(map['date'] as String),
      type: BulletType.values.byName(map['type'] as String),
      content: map['content'] as String,
      isDone: map['is_done'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'type': type.name,
      'content': content,
      'is_done': isDone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

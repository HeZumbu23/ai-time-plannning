class Decision {
  final String id;
  final String method;
  final String topic;
  final String result;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  Decision({
    required this.id,
    required this.method,
    required this.topic,
    required this.result,
    required this.details,
    required this.createdAt,
  });

  factory Decision.fromMap(Map<String, dynamic> map) {
    return Decision(
      id: map['id'] as String,
      method: map['method'] as String,
      topic: map['topic'] as String,
      result: map['result'] as String,
      details: map['details'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method': method,
      'topic': topic,
      'result': result,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Task {
  final String id;
  final String name;
  final int color;
  final int gridPosition;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.name,
    required this.color,
    required this.gridPosition,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'grid_position': gridPosition,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        name: map['name'] as String,
        color: map['color'] as int,
        gridPosition: map['grid_position'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Task copyWith({
    String? id,
    String? name,
    int? color,
    int? gridPosition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Task(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        gridPosition: gridPosition ?? this.gridPosition,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

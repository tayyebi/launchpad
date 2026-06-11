class Task {
  final String name;
  final int gridPosition;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.name,
    required this.gridPosition,
    required this.createdAt,
    required this.updatedAt,
  });

  int get color {
    final hash = name.codeUnits.fold<int>(0, (h, c) => h * 31 + c);
    final hue = hash.abs() % 360;
    return _hsvToArgb(hue, 0.7, 0.8);
  }

  static int _hsvToArgb(int hue, double saturation, double value) {
    final h = hue / 60.0;
    final s = saturation;
    final v = value;
    final hi = h.floor() % 6;
    final f = h - h.floor();
    final p = (v * (1 - s) * 255).round();
    final q = (v * (1 - s * f) * 255).round();
    final t = (v * (1 - s * (1 - f)) * 255).round();
    final v255 = (v * 255).round();

    int r, g, b;
    switch (hi) {
      case 0: r = v255; g = t; b = p; break;
      case 1: r = q; g = v255; b = p; break;
      case 2: r = p; g = v255; b = t; break;
      case 3: r = p; g = q; b = v255; break;
      case 4: r = t; g = p; b = v255; break;
      case 5: r = v255; g = p; b = q; break;
      default: r = 0; g = 0; b = 0;
    }

    return (0xFF << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'grid_position': gridPosition,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        name: map['name'] as String,
        gridPosition: map['grid_position'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Task copyWith({
    String? name,
    int? gridPosition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Task(
        name: name ?? this.name,
        gridPosition: gridPosition ?? this.gridPosition,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

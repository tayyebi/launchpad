class TimeEntry {
  final String id;
  final String taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final bool synced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeEntry({
    required this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.synced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => endTime == null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'task_id': taskId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration_seconds': durationSeconds,
        'synced': synced ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TimeEntry.fromMap(Map<String, dynamic> map) => TimeEntry(
        id: map['id'] as String,
        taskId: map['task_id'] as String,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        durationSeconds: map['duration_seconds'] as int?,
        synced: (map['synced'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  TimeEntry copyWith({
    String? id,
    String? taskId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TimeEntry(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        synced: synced ?? this.synced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

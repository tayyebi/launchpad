import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/task.dart';
import '../data/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getAll();
});

final taskByIdProvider = Provider.family<Task?, String>((ref, id) {
  final tasksAsync = ref.watch(tasksProvider);
  return tasksAsync.whenOrNull(
    data: (tasks) {
      try {
        return tasks.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    },
  );
});

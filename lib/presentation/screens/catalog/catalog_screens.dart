import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../domain/providers/providers.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _level = '';
  String _type = '';

  static const _levels = ['', 'beginner', 'intermediate', 'advanced'];
  static const _levelLabels = ['Всі', 'Початківець', 'Середній', 'Просунутий'];
  static const _types = ['', 'cardio', 'strength', 'yoga'];
  static const _typeLabels = ['Всі', 'Кардіо', 'Силові', 'Йога'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().loadWorkouts();
    });
  }

  void _applyFilter() {
    context.read<WorkoutProvider>().setFilter(level: _level, type: _type);
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Каталог тренувань')),
      body: Column(children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Рівень', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                    _levels.length,
                    (i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_levelLabels[i]),
                            selected: _level == _levels[i],
                            onSelected: (_) {
                              setState(() => _level = _levels[i]);
                              _applyFilter();
                            },
                          ),
                        )),
              ),
            ),
            const SizedBox(height: 4),
            Text('Тип', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                    _types.length,
                    (i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_typeLabels[i]),
                            selected: _type == _types[i],
                            onSelected: (_) {
                              setState(() => _type = _types[i]);
                              _applyFilter();
                            },
                          ),
                        )),
              ),
            ),
          ]),
        ),
        const Divider(height: 16),
        // Workout list
        Expanded(
          child: wp.loading
              ? const Center(child: CircularProgressIndicator())
              : wp.workouts.isEmpty
                  ? const Center(child: Text('Тренувань не знайдено'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: wp.workouts.length,
                      itemBuilder: (_, i) {
                        final w = wp.workouts[i];
                        return _WorkoutListTile(
                          workout: w,
                          onTap: () => context.go('/catalog/${w.id}'),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

class _WorkoutListTile extends StatelessWidget {
  final dynamic workout;
  final VoidCallback onTap;
  const _WorkoutListTile({required this.workout, required this.onTap});

  IconData get _typeIcon {
    switch (workout.type) {
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.sports;
    }
  }

  Color get _levelColor {
    switch (workout.difficultyLevel) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon,
                  color: Theme.of(context).colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(workout.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _levelColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(workout.difficultyLevel,
                            style: TextStyle(fontSize: 11, color: _levelColor)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 2),
                      Text('${workout.durationMin} хв',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline)),
                      const Spacer(),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(' ${workout.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12)),
                    ]),
                  ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}

// ─── Workout Detail Screen ──────────────────────────────────────────────────
class WorkoutDetailScreen extends StatefulWidget {
  final int workoutId;
  const WorkoutDetailScreen({super.key, required this.workoutId});
  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().selectWorkout(widget.workoutId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();
    final w = wp.selected;
    if (w == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(w.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.fitness_center, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(w.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                _Chip('${w.durationMin} хв', Icons.timer_outlined),
                const SizedBox(width: 8),
                _Chip(w.difficultyLevel, Icons.signal_cellular_alt),
                const SizedBox(width: 8),
                _Chip(w.type, Icons.category_outlined),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Description
          Text('Опис',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(w.description),
          const SizedBox(height: 20),

          // Exercises list
          Text('Вправи (${wp.selectedExercises.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...wp.selectedExercises.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${e['sets']}×',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text(e['name']),
                  subtitle: Text(e['description'] ?? ''),
                  trailing: Text('${e['reps']} повт.',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
          const SizedBox(height: 24),

          // Start button
          ElevatedButton.icon(
            onPressed: () => context.go('/tracking/active/${w.id}'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Почати тренування'),
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip(this.label, this.icon);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      );
}

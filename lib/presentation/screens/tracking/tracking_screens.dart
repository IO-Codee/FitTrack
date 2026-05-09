import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/providers.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final int workoutId;
  const ActiveWorkoutScreen({super.key, required this.workoutId});
  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Timer _timer;
  int _seconds = 0;
  final List<Map<String, dynamic>> _logs = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    context.read<WorkoutProvider>().selectWorkout(widget.workoutId);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _addLog(int exerciseId, int reps, double weight) {
    setState(() => _logs.add({
          'exercise_id': exerciseId,
          'reps': reps,
          'weight': weight, // 0.0 valid per BRL-10
        }));
  }

  Future<void> _finish() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Додайте хоча б один підхід')),
      );
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final tracking = context.read<TrackingProvider>();
    try {
      await tracking.saveWorkoutResult(
        userId: auth.currentUser!.id!, // DEF-IT-01 fix: passed explicitly
        workoutId: widget.workoutId,
        exerciseLogs: _logs,
        durationSec: _seconds,
      );
      if (mounted) {
        _timer.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Тренування збережено!'),
              backgroundColor: Colors.green),
        );
        context.go('/tracking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkoutProvider>();
    final exercises = wp.selectedExercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(wp.selected?.title ?? 'Тренування'),
        actions: [
          Center(
              child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(_timeLabel,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
      body: Column(children: [
        // Progress bar
        LinearProgressIndicator(
          value: exercises.isEmpty ? 0 : _logs.length / exercises.length,
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Підходів зафіксовано: ${_logs.length}',
              style: Theme.of(context).textTheme.bodySmall),
        ),

        Expanded(
          child: exercises.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: exercises.length,
                  itemBuilder: (_, i) => _ExerciseInputCard(
                    exercise: exercises[i],
                    onLog: (reps, weight) =>
                        _addLog(exercises[i]['id'], reps, weight),
                  ),
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: _saving
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.check),
                  label: const Text('Завершити тренування'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
        ),
      ]),
    );
  }
}

class _ExerciseInputCard extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final void Function(int reps, double weight) onLog;
  const _ExerciseInputCard({required this.exercise, required this.onLog});
  @override
  State<_ExerciseInputCard> createState() => _ExerciseInputCardState();
}

class _ExerciseInputCardState extends State<_ExerciseInputCard> {
  final _repsCtrl = TextEditingController(text: '12');
  final _weightCtrl = TextEditingController(text: '0');
  bool _logged = false;

  void _log() {
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    final weight = double.tryParse(_weightCtrl.text) ?? 0.0; // BRL-10: 0 valid
    if (reps <= 0) return;
    widget.onLog(reps, weight);
    setState(() => _logged = true);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _logged ? Colors.green.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(widget.exercise['name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            if (_logged) const Icon(Icons.check_circle, color: Colors.green),
          ]),
          Text('Ціль: ${widget.exercise['sets']}×${widget.exercise['reps']}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Повторень', isDense: true),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Вага (кг)',
                  helperText: '0 = без ваги',
                  isDense: true),
            )),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _logged ? null : _log,
              style: ElevatedButton.styleFrom(minimumSize: const Size(60, 40)),
              child: const Text('✓'),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Tracking / Progress Screen ─────────────────────────────────────────────
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<TrackingProvider>().loadHistory(auth.currentUser!.id!);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мій прогрес'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Історія'), Tab(text: 'Статистика')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // History tab
          tracking.loading
              ? const Center(child: CircularProgressIndicator())
              : tracking.logs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Ще немає тренувань'),
                          Text('Виберіть тренування з каталогу!',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tracking.logs.length,
                      itemBuilder: (_, i) {
                        final log = tracking.logs[i];
                        final date =
                            DateTime.fromMillisecondsSinceEpoch(log.date);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              child: Icon(Icons.fitness_center,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text('Тренування #${log.id}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${date.day}.${date.month}.${date.year}  •  '
                                '${(log.durationSec / 60).round()} хв'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${log.totalVolume.toStringAsFixed(0)} кг',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const Text('об\'єм',
                                    style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

          // Stats tab
          _StatsTab(stats: tracking.stats),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/catalog'),
        icon: const Icon(Icons.add),
        label: const Text('Нове тренування'),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  const _StatsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Center(child: Text('Немає даних для відображення'));
    }
    final total = stats.fold<double>(
        0, (s, e) => s + ((e['volume'] as num?)?.toDouble() ?? 0));
    final sessions =
        stats.fold<int>(0, (s, e) => s + ((e['count'] as int?) ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _BigStat(value: '$sessions', label: 'Тренувань')),
          const SizedBox(width: 12),
          Expanded(
              child: _BigStat(
                  value: '${total.toStringAsFixed(0)} кг',
                  label: 'Загальний об\'єм')),
        ]),
        const SizedBox(height: 20),
        Text('Активність (30 днів)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // Simple bar chart using containers
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: stats.take(14).map((s) {
              final count = (s['count'] as int?) ?? 0;
              return Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: (count * 30.0).clamp(4.0, 100.0),
                      width: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value, label;
  const _BigStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}

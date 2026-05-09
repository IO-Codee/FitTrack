import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/providers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<TrackingProvider>().loadHistory(auth.currentUser!.id!);
        context.read<WorkoutProvider>().loadWorkouts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tracking = context.watch<TrackingProvider>();
    final workouts = context.watch<WorkoutProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await tracking.loadHistory(user.id!);
            await workouts.loadWorkouts();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              _GreetingCard(name: user?.name ?? 'Спортсмен'),
              const SizedBox(height: 20),

              // Stats row
              _StatsRow(logs: tracking.logs),
              const SizedBox(height: 20),

              // Quick actions
              Text('Швидкий старт',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.fitness_center,
                    label: 'Каталог\nтренувань',
                    color: Colors.blue,
                    onTap: () => context.go('/catalog'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Мої\nплани',
                    color: Colors.green,
                    onTap: () => context.go('/plans'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.bar_chart,
                    label: 'Мій\nпрогрес',
                    color: Colors.orange,
                    onTap: () => context.go('/tracking'),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // Recent workouts
              if (tracking.logs.isNotEmpty) ...[
                Text('Останні тренування',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 12),
                ...tracking.logs
                    .take(3)
                    .map((log) => _RecentWorkoutTile(log: log)),
              ],

              // Recommended workouts
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Рекомендовано',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.go('/catalog'),
                    child: const Text('Усі'),
                  ),
                ],
              ),
              SizedBox(
                height: 180,
                child: workouts.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: workouts.workouts.take(5).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final w = workouts.workouts[i];
                          return _WorkoutCard(
                            workout: w,
                            onTap: () => context.go('/catalog/${w.id}'),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  const _GreetingCard({required this.name});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброго ранку';
    if (h < 17) return 'Добрий день';
    return 'Добрий вечір';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$_greeting, $name! 👋',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Готовий до тренування?',
            style: TextStyle(color: Colors.white70)),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List logs;
  const _StatsRow({required this.logs});

  @override
  Widget build(BuildContext context) {
    final thisWeek = logs.where((l) {
      final d = DateTime.fromMillisecondsSinceEpoch(l.date);
      final now = DateTime.now();
      return now.difference(d).inDays <= 7;
    }).length;

    return Row(children: [
      Expanded(
          child: _StatCard(
              value: '$thisWeek',
              label: 'Цього тижня',
              icon: Icons.calendar_today)),
      const SizedBox(width: 12),
      Expanded(
          child: _StatCard(
              value: '${logs.length}',
              label: 'Всього',
              icon: Icons.emoji_events)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _StatCard(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _RecentWorkoutTile extends StatelessWidget {
  final dynamic log;
  const _RecentWorkoutTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(log.date);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading:
            const CircleAvatar(child: Icon(Icons.fitness_center, size: 18)),
        title: Text(log.notes ?? 'Тренування'),
        subtitle: Text(
            '${date.day}.${date.month}.${date.year}  •  ${(log.durationSec / 60).round()} хв'),
        trailing: Text('${log.totalVolume.toStringAsFixed(0)} кг',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final dynamic workout;
  final VoidCallback onTap;
  const _WorkoutCard({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.fitness_center,
              color: Theme.of(context).colorScheme.primary, size: 32),
          const Spacer(),
          Text(workout.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text('${workout.durationMin} хв',
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(workout.difficultyLevel,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary)),
          ),
        ]),
      ),
    );
  }
}

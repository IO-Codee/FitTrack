import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/providers.dart';
import '../../../data/database/database_helper.dart';
import '../../../main.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<PlanProvider>().loadPlans(auth.currentUser!.id!);
      }
    });
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    String goal = 'Загальна фізична форма';
    String level = 'beginner';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новий план'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Назва плану'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: goal,
              decoration: const InputDecoration(labelText: 'Ціль'),
              items: ['Схуднення', 'Набір м\'язів', 'Загальна фізична форма', 'Витривалість']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => goal = v ?? goal,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: level,
              decoration: const InputDecoration(labelText: 'Рівень'),
              items: ['beginner', 'intermediate', 'advanced']
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => level = v ?? level,
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              try {
                final id = await context.read<PlanProvider>().createPlan(
                  userId: auth.currentUser!.id!,
                  name: nameCtrl.text.trim(),
                  goal: goal,
                  difficultyLevel: level,
                );
                if (mounted) context.go('/plans/$id');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Створити'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<PlanProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Мої плани')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Новий план'),
      ),
      body: plans.loading
          ? const Center(child: CircularProgressIndicator())
          : plans.plans.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Немає планів'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                        onPressed: _showCreateDialog, child: const Text('Створити план')),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.plans.length,
                  itemBuilder: (_, i) {
                    final p = plans.plans[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.list_alt,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.goal}  •  ${p.difficultyLevel}  •  ${p.durationWeeks} тижнів'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final auth = context.read<AuthProvider>();
                            await context.read<PlanProvider>().deletePlan(p.id!, auth.currentUser!.id!);
                          },
                        ),
                        onTap: () => context.go('/plans/${p.id}'),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── Plan Detail Screen ──────────────────────────────────────────────────────
class PlanDetailScreen extends StatefulWidget {
  final int planId;
  const PlanDetailScreen({super.key, required this.planId});
  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlanExercises(widget.planId);
    });
  }

  void _showAddExercise() async {
    final db = context.read<PlanProvider>();
    final allEx = db.plans; // we'll load from DB directly
    // Simple dialog to pick an exercise
    final exercises = await _loadExercises();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Додати вправу'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: exercises.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(exercises[i]['name']),
              subtitle: Text(exercises[i]['type']),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<PlanProvider>().addExercise(
                  widget.planId,
                  exercises[i]['id'],
                );
              },
            ),
          ),
        ),
        actions: [TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Скасувати'),
        )],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadExercises() async {
    return await DatabaseHelper().getAllExercises();
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanProvider>();
    final exercises = plan.currentPlanExercises;

    return Scaffold(
      appBar: AppBar(title: const Text('Деталі плану')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExercise,
        child: const Icon(Icons.add),
      ),
      body: exercises.isEmpty
          ? const Center(child: Text('Додайте вправи до плану'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (_, i) {
                final e = exercises[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.sports)),
                    title: Text(e['name'] ?? ''),
                    subtitle: Text('${e['sets']} підходів × ${e['reps']} повт. • ${e['weight']} кг'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => context.read<PlanProvider>()
                          .removeExercise(e['plan_exercise_id'], widget.planId),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Profile Screen ──────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _darkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<ProfileProvider>().loadProfile(auth.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final user = profile.profile ?? auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Профіль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(Icons.person,
                size: 48, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          if (user?.goal != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Chip(label: Text(user!.goal!)),
            ),
          const SizedBox(height: 24),

          // Actions
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Редагувати профіль'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/profile/edit'),
              ),
              const Divider(height: 0),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Темна тема'), // BRL-8
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  context.findAncestorStateOfType<FitTrackAppState>()?.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Вийти', style: TextStyle(color: Colors.red)),
                onTap: () {
                  auth.logout();
                  context.go('/login');
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Edit Profile Screen ─────────────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  String _goal = '';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.currentUser?.name ?? '';
    _goal = auth.currentUser?.goal ?? 'Загальна фізична форма';
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    await context.read<ProfileProvider>().updateProfile(
      auth.currentUser!.id!,
      name: _nameCtrl.text,
      goal: _goal,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Збережено'), backgroundColor: Colors.green),
      );
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Редагування профілю')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Ім\'я',
              prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _goal.isNotEmpty ? _goal : null,
          decoration: const InputDecoration(labelText: 'Ціль тренувань'),
          items: ['Схуднення', 'Набір м\'язів', 'Загальна фізична форма', 'Витривалість', 'Гнучкість']
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) => setState(() => _goal = v ?? _goal),
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _save, child: const Text('Зберегти зміни')),
      ]),
    ),
  );
}

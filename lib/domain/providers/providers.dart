import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/workout_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/models.dart';

class WorkoutProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  WorkoutProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  List<WorkoutModel> _workouts = [];
  WorkoutModel? _selected;
  List<Map<String, dynamic>> _selectedExercises = [];
  bool _loading = false;
  String _filterLevel = '';
  String _filterType = '';

  List<WorkoutModel> get workouts => _workouts;
  WorkoutModel? get selected => _selected;
  List<Map<String, dynamic>> get selectedExercises => _selectedExercises;
  bool get loading => _loading;
  String get filterLevel => _filterLevel;
  String get filterType => _filterType;

  Future<void> loadWorkouts({String? level, String? type}) async {
    _loading = true;
    notifyListeners();
    try {
      _filterLevel = level ?? _filterLevel;
      _filterType = type ?? _filterType;
      final rows = await _db.getWorkouts(
        level: _filterLevel.isEmpty ? null : _filterLevel,
        type: _filterType.isEmpty ? null : _filterType,
      );
      _workouts = rows.map(WorkoutModel.fromMap).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFilter({String level = '', String type = ''}) {
    _filterLevel = level;
    _filterType = type;
    loadWorkouts(level: level, type: type);
  }

  Future<void> selectWorkout(int id) async {
    final row = await _db.getWorkoutById(id);
    _selected = row != null ? WorkoutModel.fromMap(row) : null;
    _selectedExercises = await _db.getWorkoutExercises(id);
    notifyListeners();
  }

  void clearSelected() {
    _selected = null;
    _selectedExercises = [];
    notifyListeners();
  }
}

// lib/domain/providers/tracking_provider.dart

class TrackingProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  TrackingProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  List<WorkoutLogModel> _logs = [];
  final List<ExerciseLogModel> _currentExerciseLogs = [];
  List<Map<String, dynamic>> _stats = [];
  bool _loading = false;

  List<WorkoutLogModel> get logs => _logs;
  List<ExerciseLogModel> get currentExerciseLogs => _currentExerciseLogs;
  List<Map<String, dynamic>> get stats => _stats;
  bool get loading => _loading;

  /// Save full workout result — requires userId to be passed explicitly
  /// (DEF-IT-01 fix: userId is NOT retrieved from inside this provider)
  Future<int> saveWorkoutResult({
    required int userId,
    required int workoutId,
    required List<Map<String, dynamic>> exerciseLogs,
    int durationSec = 0,
    String? notes,
  }) async {
    // Validate (DEF-ST-02 fix: weight >= 0 is valid — BRL-10)
    for (final log in exerciseLogs) {
      final w = (log['weight'] as num?)?.toDouble() ?? 0.0;
      if (w < 0) throw ArgumentError('weight must be >= 0 (BRL-10)');
    }

    final totalVolume = exerciseLogs.fold<double>(0, (sum, l) {
      return sum +
          (l['reps'] as int) * ((l['weight'] as num?)?.toDouble() ?? 0.0);
    });

    final logId = await _db.insertWorkoutLog({
      'user_id': userId,
      'workout_id': workoutId,
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration_sec': durationSec,
      'total_volume': totalVolume,
      'notes': notes,
    });

    for (int i = 0; i < exerciseLogs.length; i++) {
      await _db.insertExerciseLog({
        'log_id': logId,
        'exercise_id': exerciseLogs[i]['exercise_id'],
        'set_number': i + 1,
        'reps': exerciseLogs[i]['reps'],
        'weight': exerciseLogs[i]['weight'] ?? 0.0,
      });
    }

    await loadHistory(userId);
    return logId;
  }

  Future<void> loadHistory(int userId) async {
    _loading = true;
    notifyListeners();
    try {
      final rows = await _db.getWorkoutLogs(userId);
      _logs = rows.map(WorkoutLogModel.fromMap).toList();
      _stats = await _db.getProgressStats(userId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getExerciseLogs(int logId) async {
    final result = await _db.getExerciseLogs(logId);
    return result;
  }

  Future<bool> editExerciseLog(int id, {int? reps, double? weight}) async {
    final data = <String, dynamic>{};
    if (reps != null) data['reps'] = reps;
    if (weight != null) {
      if (weight < 0) throw ArgumentError('weight must be >= 0');
      data['weight'] = weight;
    }
    final count = await _db.updateExerciseLog(id, data);
    notifyListeners();
    return count > 0;
  }
}

// lib/domain/providers/plan_provider.dart

class PlanProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  PlanProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  List<PlanModel> _plans = [];
  List<Map<String, dynamic>> _currentPlanExercises = [];
  bool _loading = false;

  List<PlanModel> get plans => _plans;
  List<Map<String, dynamic>> get currentPlanExercises => _currentPlanExercises;
  bool get loading => _loading;

  Future<void> loadPlans(int userId) async {
    _loading = true;
    notifyListeners();
    try {
      final rows = await _db.getUserPlans(userId);
      _plans = rows.map(PlanModel.fromMap).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> createPlan({
    required int userId,
    required String name,
    required String goal,
    required String difficultyLevel,
    int durationWeeks = 4,
  }) async {
    if (name.trim().isEmpty)
      throw ArgumentError('Назва плану не може бути порожньою');
    final id = await _db.insertPlan({
      'user_id': userId,
      'name': name.trim(),
      'goal': goal,
      'difficulty_level': difficultyLevel,
      'duration_weeks': durationWeeks,
      'is_public': 0,
    });
    await loadPlans(userId);
    return id;
  }

  Future<bool> editPlan(
      int planId, int userId, Map<String, dynamic> data) async {
    final count = await _db.updatePlan(planId, data);
    await loadPlans(userId);
    return count > 0;
  }

  Future<bool> deletePlan(int planId, int userId) async {
    final count = await _db.deletePlan(planId);
    await loadPlans(userId);
    return count > 0;
  }

  Future<bool> addExercise(int planId, int exerciseId,
      {int sets = 3, int reps = 12, double weight = 0.0}) async {
    await _db.addExerciseToPlan({
      'plan_id': planId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    });
    await loadPlanExercises(planId);
    return true;
  }

  Future<void> loadPlanExercises(int planId) async {
    _currentPlanExercises = await _db.getPlanExercises(planId);
    notifyListeners();
  }

  Future<bool> removeExercise(int planExerciseId, int planId) async {
    final count = await _db.removeExerciseFromPlan(planExerciseId);
    await loadPlanExercises(planId);
    return count > 0;
  }
}

// lib/domain/providers/profile_provider.dart

class ProfileProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  ProfileProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  UserModel? _profile;
  bool _loading = false;

  UserModel? get profile => _profile;
  bool get loading => _loading;

  Future<void> loadProfile(int userId) async {
    _loading = true;
    notifyListeners();
    try {
      final row = await _db.getUserById(userId);
      _profile = row != null ? UserModel.fromMap(row) : null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(int userId, {String? name, String? goal}) async {
    final data = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) data['name'] = name.trim();
    if (goal != null) data['goal'] = goal;
    if (data.isEmpty) return false;
    final count = await _db.updateUser(userId, data);
    await loadProfile(userId);
    return count > 0;
  }
}

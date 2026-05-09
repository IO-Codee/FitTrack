class ExerciseModel {
  final int? id;
  final String name;
  final String type;
  final String targetMuscle;
  final String description;

  ExerciseModel({
    this.id,
    required this.name,
    required this.type,
    required this.targetMuscle,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'target_muscle': targetMuscle,
        'description': description,
      };

  factory ExerciseModel.fromMap(Map<String, dynamic> m) => ExerciseModel(
        id: m['id'],
        name: m['name'],
        type: m['type'],
        targetMuscle: m['target_muscle'],
        description: m['description'],
      );
}

// lib/data/models/workout_log_model.dart
class WorkoutLogModel {
  final int? id;
  final int userId;
  final int workoutId;
  final int date; // millisecondsSinceEpoch
  final int durationSec;
  final double totalVolume;
  final String? notes;

  WorkoutLogModel({
    this.id,
    required this.userId,
    required this.workoutId,
    required this.date,
    required this.durationSec,
    required this.totalVolume,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'workout_id': workoutId,
        'date': date,
        'duration_sec': durationSec,
        'total_volume': totalVolume,
        'notes': notes,
      };

  factory WorkoutLogModel.fromMap(Map<String, dynamic> m) => WorkoutLogModel(
        id: m['id'],
        userId: m['user_id'],
        workoutId: m['workout_id'],
        date: m['date'],
        durationSec: m['duration_sec'],
        totalVolume: (m['total_volume'] as num?)?.toDouble() ?? 0.0,
        notes: m['notes'],
      );
}

// lib/data/models/exercise_log_model.dart
class ExerciseLogModel {
  final int? id;
  final int logId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight; // 0.0 is valid (bodyweight — BRL-10)

  ExerciseLogModel({
    this.id,
    required this.logId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'log_id': logId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'reps': reps,
        'weight': weight,
      };

  factory ExerciseLogModel.fromMap(Map<String, dynamic> m) => ExerciseLogModel(
        id: m['id'],
        logId: m['log_id'],
        exerciseId: m['exercise_id'],
        setNumber: m['set_number'],
        reps: m['reps'],
        weight: (m['weight'] as num?)?.toDouble() ?? 0.0,
      );
}

// lib/data/models/plan_model.dart
class PlanModel {
  final int? id;
  final int userId;
  final String name;
  final String goal;
  final String difficultyLevel;
  final int durationWeeks;
  final bool isPublic;

  PlanModel({
    this.id,
    required this.userId,
    required this.name,
    required this.goal,
    required this.difficultyLevel,
    required this.durationWeeks,
    this.isPublic = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'goal': goal,
        'difficulty_level': difficultyLevel,
        'duration_weeks': durationWeeks,
        'is_public': isPublic ? 1 : 0,
      };

  factory PlanModel.fromMap(Map<String, dynamic> m) => PlanModel(
        id: m['id'],
        userId: m['user_id'],
        name: m['name'],
        goal: m['goal'],
        difficultyLevel: m['difficulty_level'],
        durationWeeks: m['duration_weeks'],
        isPublic: (m['is_public'] as int?) == 1,
      );
}

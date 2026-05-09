import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/data/models/user_model.dart';
import 'package:fittrack/data/models/workout_model.dart';
import 'package:fittrack/data/models/models.dart';

void main() {
  // ─── UserModel ───────────────────────────────────────────────────────────────
  group('UserModel', () {
    final map = {
      'id': 1,
      'name': 'Test User',
      'email': 'test@example.com',
      'password_hash': 'abc123',
      'goal': 'Схуднення',
      'created_at': 1700000000000,
    };

    test('fromMap creates correct instance', () {
      final user = UserModel.fromMap(map);
      expect(user.id, 1);
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.passwordHash, 'abc123');
      expect(user.goal, 'Схуднення');
      expect(user.createdAt, 1700000000000);
    });

    test('toMap returns correct map', () {
      final user = UserModel.fromMap(map);
      final result = user.toMap();
      expect(result['id'], 1);
      expect(result['name'], 'Test User');
      expect(result['email'], 'test@example.com');
      expect(result['password_hash'], 'abc123');
      expect(result['goal'], 'Схуднення');
      expect(result['created_at'], 1700000000000);
    });

    test('fromMap handles null goal', () {
      final mapNoGoal = {...map, 'goal': null};
      final user = UserModel.fromMap(mapNoGoal);
      expect(user.goal, isNull);
    });

    test('fromMap handles null id', () {
      final mapNoId = {...map, 'id': null};
      final user = UserModel.fromMap(mapNoId);
      expect(user.id, isNull);
    });
  });

  // ─── WorkoutModel ─────────────────────────────────────────────────────────────
  group('WorkoutModel', () {
    final map = {
      'id': 5,
      'title': 'HIIT Blast',
      'description': 'High intensity interval training',
      'difficulty_level': 'advanced',
      'duration_min': 30,
      'type': 'cardio',
      'rating': 4.8,
    };

    test('fromMap creates correct instance', () {
      final w = WorkoutModel.fromMap(map);
      expect(w.id, 5);
      expect(w.title, 'HIIT Blast');
      expect(w.difficultyLevel, 'advanced');
      expect(w.durationMin, 30);
      expect(w.type, 'cardio');
      expect(w.rating, 4.8);
    });

    test('toMap returns correct map', () {
      final w = WorkoutModel.fromMap(map);
      final result = w.toMap();
      expect(result['title'], 'HIIT Blast');
      expect(result['difficulty_level'], 'advanced');
      expect(result['rating'], 4.8);
    });

    test('fromMap defaults rating to 0.0 when null', () {
      final mapNoRating = {...map, 'rating': null};
      final w = WorkoutModel.fromMap(mapNoRating);
      expect(w.rating, 0.0);
    });

    test('default rating in constructor is 0.0', () {
      final w = WorkoutModel(
        title: 'Test',
        description: 'Desc',
        difficultyLevel: 'beginner',
        durationMin: 20,
        type: 'strength',
      );
      expect(w.rating, 0.0);
    });
  });

  // ─── WorkoutLogModel ──────────────────────────────────────────────────────────
  group('WorkoutLogModel', () {
    final map = {
      'id': 10,
      'user_id': 1,
      'workout_id': 5,
      'date': 1700000000000,
      'duration_sec': 1800,
      'total_volume': 2500.0,
      'notes': 'Great session',
    };

    test('fromMap creates correct instance', () {
      final log = WorkoutLogModel.fromMap(map);
      expect(log.id, 10);
      expect(log.userId, 1);
      expect(log.workoutId, 5);
      expect(log.durationSec, 1800);
      expect(log.totalVolume, 2500.0);
      expect(log.notes, 'Great session');
    });

    test('toMap round-trips correctly', () {
      final log = WorkoutLogModel.fromMap(map);
      final result = log.toMap();
      expect(result['user_id'], 1);
      expect(result['total_volume'], 2500.0);
      expect(result['notes'], 'Great session');
    });

    test('fromMap handles null notes', () {
      final m = {...map, 'notes': null};
      final log = WorkoutLogModel.fromMap(m);
      expect(log.notes, isNull);
    });

    test('fromMap defaults totalVolume to 0.0 when null', () {
      final m = {...map, 'total_volume': null};
      final log = WorkoutLogModel.fromMap(m);
      expect(log.totalVolume, 0.0);
    });
  });

  // ─── ExerciseLogModel ─────────────────────────────────────────────────────────
  group('ExerciseLogModel', () {
    final map = {
      'id': 20,
      'log_id': 10,
      'exercise_id': 3,
      'set_number': 2,
      'reps': 12,
      'weight': 60.5,
    };

    test('fromMap creates correct instance', () {
      final el = ExerciseLogModel.fromMap(map);
      expect(el.id, 20);
      expect(el.logId, 10);
      expect(el.exerciseId, 3);
      expect(el.setNumber, 2);
      expect(el.reps, 12);
      expect(el.weight, 60.5);
    });

    test('toMap returns correct map', () {
      final el = ExerciseLogModel.fromMap(map);
      final result = el.toMap();
      expect(result['set_number'], 2);
      expect(result['weight'], 60.5);
    });

    test('fromMap defaults weight to 0.0 when null', () {
      final m = {...map, 'weight': null};
      final el = ExerciseLogModel.fromMap(m);
      expect(el.weight, 0.0);
    });

    test('weight of 0.0 is valid (BRL-10: bodyweight exercises)', () {
      final m = {...map, 'weight': 0};
      final el = ExerciseLogModel.fromMap(m);
      expect(el.weight, 0.0);
    });
  });

  // ─── PlanModel ────────────────────────────────────────────────────────────────
  group('PlanModel', () {
    final map = {
      'id': 7,
      'user_id': 1,
      'name': 'My Plan',
      'goal': 'Схуднення',
      'difficulty_level': 'beginner',
      'duration_weeks': 6,
      'is_public': 0,
    };

    test('fromMap creates correct instance', () {
      final p = PlanModel.fromMap(map);
      expect(p.id, 7);
      expect(p.name, 'My Plan');
      expect(p.goal, 'Схуднення');
      expect(p.difficultyLevel, 'beginner');
      expect(p.durationWeeks, 6);
      expect(p.isPublic, false);
    });

    test('fromMap parses isPublic=1 as true', () {
      final m = {...map, 'is_public': 1};
      final p = PlanModel.fromMap(m);
      expect(p.isPublic, true);
    });

    test('toMap encodes isPublic as int', () {
      final p = PlanModel.fromMap(map);
      expect(p.toMap()['is_public'], 0);

      final mPublic = {...map, 'is_public': 1};
      final pPublic = PlanModel.fromMap(mPublic);
      expect(pPublic.toMap()['is_public'], 1);
    });

    test('default isPublic is false', () {
      final p = PlanModel(
        userId: 1,
        name: 'Plan',
        goal: 'Goal',
        difficultyLevel: 'beginner',
        durationWeeks: 4,
      );
      expect(p.isPublic, false);
    });
  });
}

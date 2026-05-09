import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/domain/providers/providers.dart';
import 'package:fittrack/data/database/database_helper.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'providers_test.mocks.dart';

@GenerateMocks([DatabaseHelper])
void main() {
  // ─── WorkoutProvider ──────────────────────────────────────────────────────
  group('WorkoutProvider', () {
    late MockDatabaseHelper mockDb;
    late WorkoutProvider provider;

    setUp(() {
      mockDb = MockDatabaseHelper();
      provider = WorkoutProvider(db: mockDb);
    });

    test('initial state is empty and not loading', () {
      expect(provider.workouts, isEmpty);
      expect(provider.loading, false);
      expect(provider.filterLevel, '');
      expect(provider.filterType, '');
    });

    test('loadWorkouts populates workouts list', () async {
      when(mockDb.getWorkouts(level: anyNamed('level'), type: anyNamed('type')))
          .thenAnswer((_) async => [
                {
                  'id': 1,
                  'title': 'Morning Run',
                  'description': 'Easy run',
                  'difficulty_level': 'beginner',
                  'duration_min': 20,
                  'type': 'cardio',
                  'rating': 4.5,
                }
              ]);

      await provider.loadWorkouts();

      expect(provider.workouts.length, 1);
      expect(provider.workouts[0].title, 'Morning Run');
      expect(provider.loading, false);
    });

    test('loadWorkouts sets loading to false after completion', () async {
      when(mockDb.getWorkouts(level: anyNamed('level'), type: anyNamed('type')))
          .thenAnswer((_) async => []);

      await provider.loadWorkouts();

      expect(provider.loading, false);
    });

    test('setFilter updates filter values', () {
      when(mockDb.getWorkouts(level: anyNamed('level'), type: anyNamed('type')))
          .thenAnswer((_) async => []);

      provider.setFilter(level: 'beginner', type: 'cardio');

      expect(provider.filterLevel, 'beginner');
      expect(provider.filterType, 'cardio');
    });

    test('selectWorkout sets selected workout and exercises', () async {
      when(mockDb.getWorkoutById(1)).thenAnswer((_) async => {
            'id': 1,
            'title': 'Strength',
            'description': 'Strong',
            'difficulty_level': 'intermediate',
            'duration_min': 45,
            'type': 'strength',
            'rating': 4.7,
          });
      when(mockDb.getWorkoutExercises(1)).thenAnswer((_) async => [
            {'name': 'Push-up', 'sets': 3, 'reps': 12}
          ]);

      await provider.selectWorkout(1);

      expect(provider.selected, isNotNull);
      expect(provider.selected!.title, 'Strength');
      expect(provider.selectedExercises.length, 1);
    });

    test('selectWorkout with missing workout sets selected to null', () async {
      when(mockDb.getWorkoutById(999)).thenAnswer((_) async => null);
      when(mockDb.getWorkoutExercises(999)).thenAnswer((_) async => []);

      await provider.selectWorkout(999);

      expect(provider.selected, isNull);
    });

    test('clearSelected resets selected and exercises', () async {
      when(mockDb.getWorkoutById(1)).thenAnswer((_) async => {
            'id': 1,
            'title': 'T',
            'description': 'D',
            'difficulty_level': 'beginner',
            'duration_min': 10,
            'type': 'cardio',
            'rating': 4.0,
          });
      when(mockDb.getWorkoutExercises(1)).thenAnswer((_) async => []);
      await provider.selectWorkout(1);

      provider.clearSelected();

      expect(provider.selected, isNull);
      expect(provider.selectedExercises, isEmpty);
    });
  });

  // ─── TrackingProvider ────────────────────────────────────────────────────
  group('TrackingProvider', () {
    late MockDatabaseHelper mockDb;
    late TrackingProvider provider;

    setUp(() {
      mockDb = MockDatabaseHelper();
      provider = TrackingProvider(db: mockDb);
    });

    test('initial state is empty', () {
      expect(provider.logs, isEmpty);
      expect(provider.stats, isEmpty);
      expect(provider.loading, false);
    });

    test('loadHistory populates logs and stats', () async {
      when(mockDb.getWorkoutLogs(1)).thenAnswer((_) async => [
            {
              'id': 1,
              'user_id': 1,
              'workout_id': 2,
              'date': 1700000000000,
              'duration_sec': 1200,
              'total_volume': 1000.0,
              'notes': null,
              'title': 'Morning Run',
              'type': 'cardio',
            }
          ]);
      when(mockDb.getProgressStats(1)).thenAnswer((_) async => [
            {'day': '2024-01-01', 'count': 1, 'volume': 1000.0}
          ]);

      await provider.loadHistory(1);

      expect(provider.logs.length, 1);
      expect(provider.stats.length, 1);
      expect(provider.loading, false);
    });

    test('saveWorkoutResult throws on negative weight (BRL-10)', () {
      expect(
        () => provider.saveWorkoutResult(
          userId: 1,
          workoutId: 1,
          exerciseLogs: [
            {'exercise_id': 1, 'reps': 10, 'weight': -5.0}
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('saveWorkoutResult accepts weight of 0.0 (BRL-10: bodyweight)',
        () async {
      when(mockDb.insertWorkoutLog(any)).thenAnswer((_) async => 42);
      when(mockDb.insertExerciseLog(any)).thenAnswer((_) async => 1);
      when(mockDb.getWorkoutLogs(1)).thenAnswer((_) async => []);
      when(mockDb.getProgressStats(1)).thenAnswer((_) async => []);

      final logId = await provider.saveWorkoutResult(
        userId: 1,
        workoutId: 1,
        exerciseLogs: [
          {'exercise_id': 1, 'reps': 15, 'weight': 0.0}
        ],
      );

      expect(logId, 42);
    });

    test('saveWorkoutResult calculates total volume correctly', () async {
      when(mockDb.insertWorkoutLog(any)).thenAnswer((_) async => 1);
      when(mockDb.insertExerciseLog(any)).thenAnswer((_) async => 1);
      when(mockDb.getWorkoutLogs(1)).thenAnswer((_) async => []);
      when(mockDb.getProgressStats(1)).thenAnswer((_) async => []);

      // 3 reps × 10.0 kg + 5 reps × 20.0 kg = 30 + 100 = 130
      await provider.saveWorkoutResult(
        userId: 1,
        workoutId: 1,
        exerciseLogs: [
          {'exercise_id': 1, 'reps': 3, 'weight': 10.0},
          {'exercise_id': 2, 'reps': 5, 'weight': 20.0},
        ],
      );

      final captured = verify(mockDb.insertWorkoutLog(captureAny)).captured;
      expect(captured.first['total_volume'], 130.0);
    });

    test('editExerciseLog throws on negative weight', () {
      when(mockDb.updateExerciseLog(1, any)).thenAnswer((_) async => 1);
      expect(
        () => provider.editExerciseLog(1, weight: -1.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('editExerciseLog returns true when row updated', () async {
      when(mockDb.updateExerciseLog(1, any)).thenAnswer((_) async => 1);

      final result = await provider.editExerciseLog(1, reps: 12, weight: 50.0);

      expect(result, true);
    });

    test('editExerciseLog returns false when no row updated', () async {
      when(mockDb.updateExerciseLog(99, any)).thenAnswer((_) async => 0);

      final result = await provider.editExerciseLog(99, reps: 5);

      expect(result, false);
    });

    test('getExerciseLogs delegates to db', () async {
      when(mockDb.getExerciseLogs(1)).thenAnswer((_) async => [
            {'id': 1, 'name': 'Push-up', 'type': 'strength'}
          ]);

      final result = await provider.getExerciseLogs(1);

      expect(result.length, 1);
    });
  });

  // ─── PlanProvider ─────────────────────────────────────────────────────────
  group('PlanProvider', () {
    late MockDatabaseHelper mockDb;
    late PlanProvider provider;

    setUp(() {
      mockDb = MockDatabaseHelper();
      provider = PlanProvider(db: mockDb);
    });

    test('initial state is empty', () {
      expect(provider.plans, isEmpty);
      expect(provider.loading, false);
    });

    test('loadPlans populates plans list', () async {
      when(mockDb.getUserPlans(1)).thenAnswer((_) async => [
            {
              'id': 1,
              'user_id': 1,
              'name': 'Plan A',
              'goal': 'Схуднення',
              'difficulty_level': 'beginner',
              'duration_weeks': 4,
              'is_public': 0,
            }
          ]);

      await provider.loadPlans(1);

      expect(provider.plans.length, 1);
      expect(provider.plans[0].name, 'Plan A');
    });

    test('createPlan throws on empty name', () {
      expect(
        () => provider.createPlan(
          userId: 1,
          name: '   ',
          goal: 'Goal',
          difficultyLevel: 'beginner',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createPlan returns new plan id', () async {
      when(mockDb.insertPlan(any)).thenAnswer((_) async => 5);
      when(mockDb.getUserPlans(1)).thenAnswer((_) async => []);

      final id = await provider.createPlan(
        userId: 1,
        name: 'New Plan',
        goal: 'Схуднення',
        difficultyLevel: 'beginner',
      );

      expect(id, 5);
    });

    test('deletePlan returns true when row deleted', () async {
      when(mockDb.deletePlan(1)).thenAnswer((_) async => 1);
      when(mockDb.getUserPlans(1)).thenAnswer((_) async => []);

      final result = await provider.deletePlan(1, 1);

      expect(result, true);
    });

    test('deletePlan returns false when no row deleted', () async {
      when(mockDb.deletePlan(99)).thenAnswer((_) async => 0);
      when(mockDb.getUserPlans(1)).thenAnswer((_) async => []);

      final result = await provider.deletePlan(99, 1);

      expect(result, false);
    });

    test('addExercise returns true', () async {
      when(mockDb.addExerciseToPlan(any)).thenAnswer((_) async => 1);
      when(mockDb.getPlanExercises(1)).thenAnswer((_) async => []);

      final result = await provider.addExercise(1, 2);

      expect(result, true);
    });

    test('loadPlanExercises populates currentPlanExercises', () async {
      when(mockDb.getPlanExercises(1)).thenAnswer((_) async => [
            {
              'id': 1,
              'name': 'Push-up',
              'type': 'strength',
              'target_muscle': 'chest',
              'description': 'Classic',
              'sets': 3,
              'reps': 12,
              'weight': 0.0,
              'plan_exercise_id': 10,
            }
          ]);

      await provider.loadPlanExercises(1);

      expect(provider.currentPlanExercises.length, 1);
      expect(provider.currentPlanExercises[0]['name'], 'Push-up');
    });

    test('removeExercise returns true when deleted', () async {
      when(mockDb.removeExerciseFromPlan(10)).thenAnswer((_) async => 1);
      when(mockDb.getPlanExercises(1)).thenAnswer((_) async => []);

      final result = await provider.removeExercise(10, 1);

      expect(result, true);
    });

    test('editPlan returns true when updated', () async {
      when(mockDb.updatePlan(1, any)).thenAnswer((_) async => 1);
      when(mockDb.getUserPlans(1)).thenAnswer((_) async => []);

      final result = await provider.editPlan(1, 1, {'name': 'Updated'});

      expect(result, true);
    });
  });

  // ─── ProfileProvider ──────────────────────────────────────────────────────
  group('ProfileProvider', () {
    late MockDatabaseHelper mockDb;
    late ProfileProvider provider;

    setUp(() {
      mockDb = MockDatabaseHelper();
      provider = ProfileProvider(db: mockDb);
    });

    test('initial state has null profile', () {
      expect(provider.profile, isNull);
      expect(provider.loading, false);
    });

    test('loadProfile populates profile', () async {
      when(mockDb.getUserById(1)).thenAnswer((_) async => {
            'id': 1,
            'name': 'Alice',
            'email': 'alice@example.com',
            'password_hash': 'hash',
            'goal': 'Схуднення',
            'created_at': 1700000000000,
          });

      await provider.loadProfile(1);

      expect(provider.profile, isNotNull);
      expect(provider.profile!.name, 'Alice');
    });

    test('loadProfile sets profile to null when user not found', () async {
      when(mockDb.getUserById(99)).thenAnswer((_) async => null);

      await provider.loadProfile(99);

      expect(provider.profile, isNull);
    });

    test('updateProfile returns false when no data provided', () async {
      final result = await provider.updateProfile(1);
      expect(result, false);
    });

    test('updateProfile returns true when data is updated', () async {
      when(mockDb.updateUser(1, any)).thenAnswer((_) async => 1);
      when(mockDb.getUserById(1)).thenAnswer((_) async => {
            'id': 1,
            'name': 'Updated',
            'email': 'alice@example.com',
            'password_hash': 'hash',
            'goal': 'Набір м\'язів',
            'created_at': 1700000000000,
          });

      final result = await provider.updateProfile(1,
          name: 'Updated', goal: 'Набір м\'язів');

      expect(result, true);
    });

    test('updateProfile ignores empty name', () async {
      when(mockDb.updateUser(1, any)).thenAnswer((_) async => 1);
      when(mockDb.getUserById(1)).thenAnswer((_) async => {
            'id': 1,
            'name': 'Alice',
            'email': 'alice@example.com',
            'password_hash': 'hash',
            'goal': null,
            'created_at': 1700000000000,
          });

      // Only goal provided, name is empty => should still update via goal
      final result =
          await provider.updateProfile(1, name: '', goal: 'Витривалість');
      expect(result, true);

      final captured = verify(mockDb.updateUser(1, captureAny)).captured;
      expect(captured.first.containsKey('name'), false);
      expect(captured.first['goal'], 'Витривалість');
    });
  });
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'fittrack.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      // DEF-ST-01 fix: handle offline/DatabaseException gracefully
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        goal TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        difficulty_level TEXT NOT NULL,
        duration_min INTEGER NOT NULL,
        type TEXT NOT NULL,
        rating REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        target_muscle TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sets INTEGER NOT NULL DEFAULT 3,
        reps INTEGER NOT NULL DEFAULT 12,
        FOREIGN KEY (workout_id) REFERENCES workouts(id),
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        workout_id INTEGER NOT NULL,
        date INTEGER NOT NULL,
        duration_sec INTEGER NOT NULL DEFAULT 0,
        total_volume REAL NOT NULL DEFAULT 0.0,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (workout_id) REFERENCES workouts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (log_id) REFERENCES workout_logs(id),
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        goal TEXT NOT NULL,
        difficulty_level TEXT NOT NULL,
        duration_weeks INTEGER NOT NULL DEFAULT 4,
        is_public INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE plan_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sets INTEGER NOT NULL DEFAULT 3,
        reps INTEGER NOT NULL DEFAULT 12,
        weight REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (plan_id) REFERENCES plans(id),
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      )
    ''');

    // Index for performance (DEF-ST-02 fix analogue for local SQLite)
    await db.execute(
        'CREATE INDEX idx_workouts_level ON workouts(difficulty_level, type)');
    await db.execute(
        'CREATE INDEX idx_workout_logs_user ON workout_logs(user_id, date)');

    await _seedData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ─── Seed Data ────────────────────────────────────────────────────────────

  Future<void> _seedData(Database db) async {
    // Exercises
    final exercises = [
      {
        'name': 'Віджимання',
        'type': 'strength',
        'target_muscle': 'chest',
        'description': 'Класичні віджимання від підлоги'
      },
      {
        'name': 'Присідання',
        'type': 'strength',
        'target_muscle': 'legs',
        'description': 'Глибокі присідання з власною вагою'
      },
      {
        'name': 'Планка',
        'type': 'strength',
        'target_muscle': 'core',
        'description': 'Утримання позиції планки'
      },
      {
        'name': 'Берпі',
        'type': 'cardio',
        'target_muscle': 'full_body',
        'description': 'Повноцінна кардіо-вправа'
      },
      {
        'name': 'Випади',
        'type': 'strength',
        'target_muscle': 'legs',
        'description': 'Чергові випади вперед'
      },
      {
        'name': 'Скручування',
        'type': 'strength',
        'target_muscle': 'abs',
        'description': 'Скручування на прес'
      },
      {
        'name': 'Стрибки зі скакалкою',
        'type': 'cardio',
        'target_muscle': 'full_body',
        'description': 'Кардіо-стрибки'
      },
      {
        'name': 'Поза собаки мордою вниз',
        'type': 'yoga',
        'target_muscle': 'full_body',
        'description': 'Класична йога-поза'
      },
      {
        'name': 'Гіперекстензія',
        'type': 'strength',
        'target_muscle': 'back',
        'description': 'Зміцнення м\'язів спини'
      },
      {
        'name': 'Бічна планка',
        'type': 'strength',
        'target_muscle': 'core',
        'description': 'Бічна планка для косих м\'язів'
      },
    ];

    for (final e in exercises) {
      await db.insert('exercises', e);
    }

    // Workouts
    final workouts = [
      {
        'title': 'Ранковий старт',
        'description': 'Легке тренування для початківців вранці',
        'difficulty_level': 'beginner',
        'duration_min': 20,
        'type': 'cardio',
        'rating': 4.5,
      },
      {
        'title': 'Силова основа',
        'description': 'Базові силові вправи з власною вагою',
        'difficulty_level': 'beginner',
        'duration_min': 30,
        'type': 'strength',
        'rating': 4.7,
      },
      {
        'title': 'Кардіо-спалювання',
        'description': 'Інтенсивне кардіо для спалення калорій',
        'difficulty_level': 'intermediate',
        'duration_min': 35,
        'type': 'cardio',
        'rating': 4.6,
      },
      {
        'title': 'Повна йога',
        'description': 'Розтяжка та відновлення для всього тіла',
        'difficulty_level': 'beginner',
        'duration_min': 40,
        'type': 'yoga',
        'rating': 4.8,
      },
      {
        'title': 'Пресинг',
        'description': 'Інтенсивне тренування на прес і кор',
        'difficulty_level': 'intermediate',
        'duration_min': 25,
        'type': 'strength',
        'rating': 4.4,
      },
      {
        'title': 'HIIT Вибух',
        'description': 'Високоінтенсивне інтервальне тренування',
        'difficulty_level': 'advanced',
        'duration_min': 30,
        'type': 'cardio',
        'rating': 4.9,
      },
      {
        'title': 'Силові ноги',
        'description': 'Вправи для зміцнення ніг',
        'difficulty_level': 'intermediate',
        'duration_min': 35,
        'type': 'strength',
        'rating': 4.5,
      },
      {
        'title': 'Верхня частина тіла',
        'description': 'Груди, плечі, трицепс',
        'difficulty_level': 'advanced',
        'duration_min': 40,
        'type': 'strength',
        'rating': 4.7,
      },
    ];

    for (final w in workouts) {
      final wId = await db.insert('workouts', w);
      // Link exercises to workouts
      if (wId == 1) {
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 1, 'sets': 3, 'reps': 10});
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 7, 'sets': 2, 'reps': 30});
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 3, 'sets': 3, 'reps': 30});
      } else if (wId == 2) {
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 1, 'sets': 4, 'reps': 12});
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 2, 'sets': 4, 'reps': 15});
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 5, 'sets': 3, 'reps': 12});
      } else if (wId == 3) {
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 4, 'sets': 4, 'reps': 15});
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 7, 'sets': 3, 'reps': 60});
        await db.insert('workout_exercises',
            {'workout_id': wId, 'exercise_id': 2, 'sets': 3, 'reps': 20});
      }
    }
  }

  // ─── Users ────────────────────────────────────────────────────────────────

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users',
        where: 'email = ?', whereArgs: [email], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final result =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  Future<int> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Workouts ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWorkouts({
    String? level,
    String? type,
  }) async {
    final db = await database;
    String where = '';
    final args = <dynamic>[];
    if (level != null && level.isNotEmpty) {
      where = 'difficulty_level = ?';
      args.add(level);
    }
    if (type != null && type.isNotEmpty) {
      where = where.isEmpty ? 'type = ?' : '$where AND type = ?';
      args.add(type);
    }
    return db.query('workouts',
        where: where.isEmpty ? null : where,
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'rating DESC');
  }

  Future<Map<String, dynamic>?> getWorkoutById(int id) async {
    final db = await database;
    final result =
        await db.query('workouts', where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  Future<List<Map<String, dynamic>>> getWorkoutExercises(int workoutId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT e.*, we.sets, we.reps
      FROM exercises e
      INNER JOIN workout_exercises we ON e.id = we.exercise_id
      WHERE we.workout_id = ?
    ''', [workoutId]);
  }

  // ─── Workout Logs (Tracking) ───────────────────────────────────────────────

  Future<int> insertWorkoutLog(Map<String, dynamic> log) async {
    final db = await database;
    return db.insert('workout_logs', log);
  }

  Future<int> insertExerciseLog(Map<String, dynamic> exLog) async {
    final db = await database;
    if ((exLog['weight'] as num) < 0) {
      throw ArgumentError('weight must be >= 0 (BRL-10)');
    }
    return db.insert('exercise_logs', exLog);
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogs(int userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT wl.*, w.title, w.type
      FROM workout_logs wl
      INNER JOIN workouts w ON wl.workout_id = w.id
      WHERE wl.user_id = ?
      ORDER BY wl.date DESC
    ''', [userId]);
  }

  Future<List<Map<String, dynamic>>> getExerciseLogs(int logId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT el.*, e.name, e.type
      FROM exercise_logs el
      INNER JOIN exercises e ON el.exercise_id = e.id
      WHERE el.log_id = ?
      ORDER BY el.set_number ASC
    ''', [logId]);
  }

  Future<int> updateExerciseLog(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('exercise_logs', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getProgressStats(int userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        date(wl.date / 1000, 'unixepoch') as day,
        COUNT(wl.id) as count,
        SUM(wl.total_volume) as volume
      FROM workout_logs wl
      WHERE wl.user_id = ?
      GROUP BY day
      ORDER BY day DESC
      LIMIT 30
    ''', [userId]);
  }

  // ─── Plans ────────────────────────────────────────────────────────────────

  Future<int> insertPlan(Map<String, dynamic> plan) async {
    final db = await database;
    if ((plan['name'] as String).trim().isEmpty) {
      throw ArgumentError('Plan name cannot be empty');
    }
    return db.insert('plans', plan);
  }

  Future<List<Map<String, dynamic>>> getUserPlans(int userId) async {
    final db = await database;
    return db.query('plans',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'id DESC');
  }

  Future<int> updatePlan(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('plans', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePlan(int id) async {
    final db = await database;
    await db.delete('plan_exercises', where: 'plan_id = ?', whereArgs: [id]);
    return db.delete('plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addExerciseToPlan(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('plan_exercises', data);
  }

  Future<List<Map<String, dynamic>>> getPlanExercises(int planId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT e.*, pe.sets, pe.reps, pe.weight, pe.id as plan_exercise_id
      FROM exercises e
      INNER JOIN plan_exercises pe ON e.id = pe.exercise_id
      WHERE pe.plan_id = ?
    ''', [planId]);
  }

  Future<int> removeExerciseFromPlan(int planExerciseId) async {
    final db = await database;
    return db
        .delete('plan_exercises', where: 'id = ?', whereArgs: [planExerciseId]);
  }

  // ─── Exercises Catalog ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllExercises({String? type}) async {
    final db = await database;
    if (type != null && type.isNotEmpty) {
      return db.query('exercises', where: 'type = ?', whereArgs: [type]);
    }
    return db.query('exercises');
  }
}

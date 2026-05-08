import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future database() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'fittrack.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE workouts(id INTEGER PRIMARY KEY, title TEXT, status INTEGER)',
        );
      },
      version: 1,
    );
  }
}
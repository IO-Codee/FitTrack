import 'package:flutter/material.dart';
import 'database_helper.dart';

class WorkoutProvider with ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => [..._items];

  Future addWorkout(String title) async {
    final db = await DBHelper.database();
    await db.insert('workouts', {'title': title, 'status': 0});
    notifyListeners();
  }

  Future fetchWorkouts() async {
    final db = await DBHelper.database();
    _items = await db.query('workouts');
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'workout_provider.dart';

void main() => runApp(FitTrackApp());

class FitTrackApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => WorkoutProvider(),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FitTrack - Тренування')),
      body: FutureBuilder(
        future: Provider.of<WorkoutProvider>(context, listen: false).fetchWorkouts(),
        builder: (ctx, snapshot) => snapshot.connectionState == ConnectionState.waiting
            ? Center(child: CircularProgressIndicator())
            : Consumer<WorkoutProvider>(
                builder: (ctx, data, _) => ListView.builder(
                  itemCount: data.items.length,
                  itemBuilder: (ctx, i) => ListTile(title: Text(data.items[i]['title'])),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Provider.of<WorkoutProvider>(context, listen: false).addWorkout('Базове тренування'),
        child: Icon(Icons.add),
      ),
    );
  }
}
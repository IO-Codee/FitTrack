import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF1DB954); // green accent
  static const _secondary = Color(0xFF191414);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _secondary,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: _secondary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: _primary,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}

// lib/core/constants/app_constants.dart
class AppConstants {
  static const List<String> difficultyLevels = [
    'beginner',
    'intermediate',
    'advanced'
  ];
  static const List<String> workoutTypes = [
    'cardio',
    'strength',
    'yoga',
    'flexibility'
  ];
  static const List<String> goals = [
    'Схуднення',
    'Набір м\'язової маси',
    'Покращення витривалості',
    'Гнучкість та розтяжка',
    'Загальна фізична форма',
  ];

  static const Map<String, String> levelLabels = {
    'beginner': 'Початківець',
    'intermediate': 'Середній',
    'advanced': 'Просунутий',
  };

  static const Map<String, String> typeLabels = {
    'cardio': 'Кардіо',
    'strength': 'Силові',
    'yoga': 'Йога',
    'flexibility': 'Розтяжка',
  };
}

class WorkoutModel {
  final int? id;
  final String title;
  final String description;
  final String difficultyLevel; // beginner | intermediate | advanced
  final int durationMin;
  final String type; // cardio | strength | yoga | flexibility
  final double rating;

  WorkoutModel({
    this.id,
    required this.title,
    required this.description,
    required this.difficultyLevel,
    required this.durationMin,
    required this.type,
    this.rating = 0.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'difficulty_level': difficultyLevel,
        'duration_min': durationMin,
        'type': type,
        'rating': rating,
      };

  factory WorkoutModel.fromMap(Map<String, dynamic> m) => WorkoutModel(
        id: m['id'],
        title: m['title'],
        description: m['description'],
        difficultyLevel: m['difficulty_level'],
        durationMin: m['duration_min'],
        type: m['type'],
        rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
      );
}

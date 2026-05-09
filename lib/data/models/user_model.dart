class UserModel {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String? goal;
  final int createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.goal,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'goal': goal,
        'created_at': createdAt,
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'],
        name: m['name'],
        email: m['email'],
        passwordHash: m['password_hash'],
        goal: m['goal'],
        createdAt: m['created_at'],
      );
}

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../data/database/database_helper.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _db;

  AuthProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ─── Password validation (BRL-2) ──────────────────────────────────────────
  static String? validatePassword(String password) {
    if (password.length < 8)
      return 'Пароль повинен містити щонайменше 8 символів'; // BRL-2 fix: >= 8, not 6
    if (!password.contains(RegExp(r'[0-9]')))
      return 'Пароль повинен містити цифру';
    if (!password.contains(RegExp(r'[A-Z]')))
      return 'Пароль повинен містити велику літеру';
    if (!password.contains(RegExp(r'[a-z]')))
      return 'Пароль повинен містити малу літеру';
    return null;
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode('${password}fittrack_salt_2026');
    return sha256.convert(bytes).toString();
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // Validate email
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _errorMessage = 'Невалідний формат email';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      throw ArgumentError(_errorMessage);
    }

    // Validate password (BRL-2)
    final pwError = validatePassword(password);
    if (pwError != null) {
      _errorMessage = pwError;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      throw ArgumentError(pwError);
    }

    try {
      final existing = await _db.getUserByEmail(email);
      if (existing != null) {
        _errorMessage = 'Email вже зайнятий';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final userId = await _db.insertUser({
        'name': name,
        'email': email,
        'password_hash': _hashPassword(password),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      final userData = await _db.getUserById(userId);
      if (userData != null) {
        _currentUser = UserModel.fromMap(userData);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Помилка реєстрації: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _errorMessage = 'Невалідний формат email';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      throw ArgumentError(_errorMessage);
    }

    try {
      final userData = await _db.getUserByEmail(email);
      if (userData == null) {
        _errorMessage = 'Користувача не знайдено';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final hash = _hashPassword(password);
      if (userData['password_hash'] != hash) {
        _errorMessage = 'Невірний пароль';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _currentUser = UserModel.fromMap(userData);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Помилка авторизації: $e';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  void logout() {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}

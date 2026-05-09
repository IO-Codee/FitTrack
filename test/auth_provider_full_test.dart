import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/domain/providers/auth_provider.dart';
import 'package:fittrack/data/database/database_helper.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_provider_full_test.mocks.dart';

@GenerateMocks([DatabaseHelper])
void main() {
  group('AuthProvider — register()', () {
    late MockDatabaseHelper mockDb;
    late AuthProvider auth;

    setUp(() {
      mockDb = MockDatabaseHelper();
      auth = AuthProvider(db: mockDb);
    });

    test('register succeeds with valid data', () async {
      when(mockDb.getUserByEmail('valid@example.com'))
          .thenAnswer((_) async => null);
      when(mockDb.insertUser(any)).thenAnswer((_) async => 1);
      when(mockDb.getUserById(1)).thenAnswer((_) async => {
            'id': 1,
            'name': 'Alice',
            'email': 'valid@example.com',
            'password_hash': 'hash',
            'goal': null,
            'created_at': 1700000000000,
          });

      final result = await auth.register(
        name: 'Alice',
        email: 'valid@example.com',
        password: 'Valid123!',
      );

      expect(result, true);
      expect(auth.isAuthenticated, true);
      expect(auth.currentUser?.name, 'Alice');
    });

    test('register fails when email already exists', () async {
      when(mockDb.getUserByEmail('taken@example.com')).thenAnswer((_) async => {
            'id': 1,
            'name': 'Existing',
            'email': 'taken@example.com',
            'password_hash': 'hash',
            'goal': null,
            'created_at': 1700000000000,
          });

      final result = await auth.register(
        name: 'Bob',
        email: 'taken@example.com',
        password: 'Valid123!',
      );

      expect(result, false);
      expect(auth.isAuthenticated, false);
      expect(auth.errorMessage, contains('Email'));
    });

    test('register throws ArgumentError for invalid email', () async {
      expect(
        () => auth.register(
          name: 'Alice',
          email: 'not-an-email',
          password: 'Valid123!',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('register throws ArgumentError for weak password', () async {
      expect(
        () => auth.register(
          name: 'Alice',
          email: 'valid@example.com',
          password: 'weak',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('register sets error status on db exception', () async {
      when(mockDb.getUserByEmail(any)).thenThrow(Exception('DB error'));

      final result = await auth.register(
        name: 'Alice',
        email: 'valid@example.com',
        password: 'Valid123!',
      );

      expect(result, false);
      expect(auth.status, AuthStatus.error);
    });
  });

  group('AuthProvider — login()', () {
    late MockDatabaseHelper mockDb;
    late AuthProvider auth;

    // Pre-hashed 'Valid123!' with the app salt
    // We'll use a different approach: register first via mock, then verify
    setUp(() {
      mockDb = MockDatabaseHelper();
      auth = AuthProvider(db: mockDb);
    });

    test('login throws ArgumentError for invalid email format', () {
      expect(
        () async => await auth.login(email: 'bademail', password: 'Valid123!'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('login returns false when user not found', () async {
      when(mockDb.getUserByEmail('nobody@example.com'))
          .thenAnswer((_) async => null);

      final result = await auth.login(
        email: 'nobody@example.com',
        password: 'Valid123!',
      );

      expect(result, false);
      expect(auth.isAuthenticated, false);
      expect(auth.errorMessage, isNotNull);
    });

    test('login returns false when password is wrong', () async {
      // sha256('WrongPass!'+'fittrack_salt_2026') != sha256('Valid123!'+'fittrack_salt_2026')
      when(mockDb.getUserByEmail('user@example.com')).thenAnswer((_) async => {
            'id': 1,
            'name': 'User',
            'email': 'user@example.com',
            'password_hash': 'wrong_hash_that_wont_match',
            'goal': null,
            'created_at': 1700000000000,
          });

      final result = await auth.login(
        email: 'user@example.com',
        password: 'Valid123!',
      );

      expect(result, false);
      expect(auth.errorMessage, isNotNull);
    });

    test('login succeeds with correct password hash', () async {
      // Use the same hash function: sha256('Valid123!fittrack_salt_2026')
      const correctHash =
          'b6c4e1dc8a5e3f09be4b81d97e7aee4a21fcab42fe4e84c2c9b0f2b3e8d65f91';
      // We'll mock the hash by inserting what the provider would generate
      // The AuthProvider hashes internally so we need the actual hash value.
      // Instead, let's test via a round-trip: register then login.
      when(mockDb.getUserByEmail('roundtrip@example.com'))
          .thenAnswer((_) async => null);
      when(mockDb.insertUser(any)).thenAnswer((_) async => 42);
      when(mockDb.getUserById(42)).thenAnswer((_) async => {
            'id': 42,
            'name': 'RoundTrip',
            'email': 'roundtrip@example.com',
            'password_hash': 'placeholder',
            'goal': null,
            'created_at': 1700000000000,
          });

      await auth.register(
          name: 'RoundTrip',
          email: 'roundtrip@example.com',
          password: 'Valid123!');

      // Capture the actual hash that was inserted
      final captured = verify(mockDb.insertUser(captureAny)).captured;
      final actualHash = captured.first['password_hash'] as String;

      // Now mock login with that correct hash
      when(mockDb.getUserByEmail('roundtrip@example.com'))
          .thenAnswer((_) async => {
                'id': 42,
                'name': 'RoundTrip',
                'email': 'roundtrip@example.com',
                'password_hash': actualHash,
                'goal': null,
                'created_at': 1700000000000,
              });

      final auth2 = AuthProvider(db: mockDb);
      final result = await auth2.login(
        email: 'roundtrip@example.com',
        password: 'Valid123!',
      );

      expect(result, true);
      expect(auth2.isAuthenticated, true);
    });

    test('login handles db exception gracefully', () async {
      when(mockDb.getUserByEmail(any)).thenThrow(Exception('DB down'));

      final result = await auth.login(
        email: 'user@example.com',
        password: 'Valid123!',
      );

      expect(result, false);
      expect(auth.status, AuthStatus.error);
    });
  });

  group('AuthProvider — logout()', () {
    late MockDatabaseHelper mockDb;
    late AuthProvider auth;

    setUp(() {
      mockDb = MockDatabaseHelper();
      auth = AuthProvider(db: mockDb);
    });

    test('logout clears user and sets unauthenticated status', () async {
      // Set up authenticated state via register
      when(mockDb.getUserByEmail(any)).thenAnswer((_) async => null);
      when(mockDb.insertUser(any)).thenAnswer((_) async => 1);
      when(mockDb.getUserById(1)).thenAnswer((_) async => {
            'id': 1,
            'name': 'Alice',
            'email': 'alice@example.com',
            'password_hash': 'hash',
            'goal': null,
            'created_at': 1700000000000,
          });
      await auth.register(
          name: 'Alice', email: 'alice@example.com', password: 'Valid123!');
      expect(auth.isAuthenticated, true);

      auth.logout();

      expect(auth.isAuthenticated, false);
      expect(auth.currentUser, isNull);
      expect(auth.errorMessage, isNull);
      expect(auth.status, AuthStatus.unauthenticated);
    });
  });

  group('AuthProvider — validatePassword() edge cases', () {
    test('exactly 8 chars passes (BRL-2 boundary)', () {
      expect(AuthProvider.validatePassword('Valid12!'), isNull);
    });

    test('7 chars fails', () {
      expect(AuthProvider.validatePassword('Val12!'), isNotNull);
    });

    test('no digit fails', () {
      expect(AuthProvider.validatePassword('ValidPass!'), isNotNull);
    });

    test('no uppercase fails', () {
      expect(AuthProvider.validatePassword('valid123!'), isNotNull);
    });

    test('no lowercase fails', () {
      expect(AuthProvider.validatePassword('VALID123!'), isNotNull);
    });

    test('all conditions met returns null', () {
      expect(AuthProvider.validatePassword('Valid123!'), isNull);
    });

    test('long valid password passes', () {
      expect(
          AuthProvider.validatePassword('ThisIsAVeryLongPassword1!'), isNull);
    });
  });

  group('AuthStatus enum', () {
    test('initial status is initial', () {
      final auth = AuthProvider(db: MockDatabaseHelper());
      expect(auth.status, AuthStatus.initial);
    });

    test('isAuthenticated is false initially', () {
      final auth = AuthProvider(db: MockDatabaseHelper());
      expect(auth.isAuthenticated, false);
    });

    test('errorMessage is null initially', () {
      final auth = AuthProvider(db: MockDatabaseHelper());
      expect(auth.errorMessage, isNull);
    });
  });
}

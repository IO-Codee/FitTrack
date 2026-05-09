import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/domain/providers/auth_provider.dart';

void main() {
  group('AuthProvider — validatePassword() (BRL-2)', () {
    // U01S01TC01 — valid password
    test('accepts valid password with 8+ chars, digit, upper, lower', () {
      expect(AuthProvider.validatePassword('Valid123!'), isNull);
    });

    // U01S02TC02 — boundary: exactly 8 chars → should PASS (DEF-01 fix)
    test('accepts password with exactly 8 characters', () {
      expect(AuthProvider.validatePassword('Valid12!'), isNull);
    });

    // U01S02TC03 — boundary: 7 chars → should FAIL
    test('rejects password shorter than 8 characters', () {
      expect(AuthProvider.validatePassword('Val12!'), isNotNull);
    });

    // Rejects password without digit
    test('rejects password without a digit', () {
      expect(AuthProvider.validatePassword('ValidPass!'), isNotNull);
    });

    // Rejects password without uppercase
    test('rejects password without uppercase letter', () {
      expect(AuthProvider.validatePassword('valid123!'), isNotNull);
    });

    // Rejects password without lowercase
    test('rejects password without lowercase letter', () {
      expect(AuthProvider.validatePassword('VALID123!'), isNotNull);
    });
  });

  group('AuthProvider — email validation', () {
    test('invalid email format throws ArgumentError', () async {
      final auth = AuthProvider();
      expect(
        () async =>
            await auth.login(email: 'notanemail', password: 'Valid123!'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

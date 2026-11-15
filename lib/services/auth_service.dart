import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../models/app_user.dart';
import 'database_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Autenticação local: cadastro, login, logout e sessão persistida.
/// A senha nunca é salva em texto puro: guardamos SHA-256(salt + senha).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _sessionKey = 'session_user_id';
  final _db = DatabaseService.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Restaura a sessão salva (chamado na abertura do app).
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    if (id != null) {
      _currentUser = await _db.findUserById(id);
      if (_currentUser == null) await prefs.remove(_sessionKey);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final existing = await _db.findUserRowByEmail(email.trim());
    if (existing != null) {
      throw AuthException('Este e-mail já está cadastrado.');
    }
    final salt = _generateSalt();
    try {
      final id = await _db.insertUser(
        name: name.trim(),
        email: email.trim(),
        passwordHash: _hash(password, salt),
        salt: salt,
      );
      await _startSession(AppUser(
          id: id, name: name.trim(), email: email.trim().toLowerCase()));
    } on DatabaseException {
      throw AuthException('Não foi possível concluir o cadastro.');
    }
  }

  Future<void> login({required String email, required String password}) async {
    final row = await _db.findUserRowByEmail(email.trim());
    if (row == null ||
        _hash(password, row['salt'] as String) != row['password_hash']) {
      throw AuthException('E-mail ou senha inválidos.');
    }
    await _startSession(AppUser.fromMap(row));
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> _startSession(AppUser user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, user.id);
  }

  String _generateSalt() {
    final rnd = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();
}

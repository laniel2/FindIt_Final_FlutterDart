import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Handles create account, login, logout and profile updates.
/// Data is stored on the device using SharedPreferences (JSON) - no MySQL.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _usersKey = 'users';
  static const _sessionKey = 'session_user_id';

  late SharedPreferences _prefs;
  final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final id = _prefs.getString(_sessionKey);
    if (id != null) {
      currentUser.value = _readUsers().where((u) => u.id == id).firstOrNull;
    }
  }

  List<AppUser> _readUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeUsers(List<AppUser> users) =>
      _prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _randomSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final users = _readUsers();
    final mail = email.trim().toLowerCase();
    if (users.any((u) => u.email == mail)) {
      throw AuthException('An account with this email already exists.');
    }
    final salt = _randomSalt();
    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fullName: fullName.trim(),
      email: mail,
      salt: salt,
      passwordHash: _hash(password, salt),
    );
    await _writeUsers([...users, user]);
    await _prefs.setString(_sessionKey, user.id);
    currentUser.value = user;
    return user;
  }

  Future<AppUser> login(String email, String password) async {
    final mail = email.trim().toLowerCase();
    final user = _readUsers().where((u) => u.email == mail).firstOrNull;
    if (user == null || user.passwordHash != _hash(password, user.salt)) {
      throw AuthException('Incorrect email or password.');
    }
    await _prefs.setString(_sessionKey, user.id);
    currentUser.value = user;
    return user;
  }

  Future<void> logout() async {
    await _prefs.remove(_sessionKey);
    currentUser.value = null;
  }

  Future<void> updateProfile(AppUser updated) async {
    final users = _readUsers();
    final index = users.indexWhere((u) => u.id == updated.id);
    if (index == -1) throw AuthException('User not found.');
    users[index] = updated;
    await _writeUsers(users);
    currentUser.value = updated;
  }
}

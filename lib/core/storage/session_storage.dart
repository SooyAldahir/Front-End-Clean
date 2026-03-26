import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacena y recupera el objeto de sesión del usuario (SharedPreferences).
class SessionStorage {
  static const _keyUser  = 'user';
  static const _keyToken = 'session_token';
  static const _keyFcm   = 'last_fcm_token_sent';

  Future<void> saveSession(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
  }

  Future<String?> getLastFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcm);
  }

  Future<void> saveLastFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcm, token);
  }

  Future<int?> getUserId() async {
    final user = await getUser();
    if (user == null) return null;
    final raw = user['id_usuario'] ?? user['IdUsuario'] ?? user['id'];
    if (raw == null) return null;
    return raw is int ? raw : int.tryParse(raw.toString());
  }

  Future<int?> getFamiliaId() async {
    final user = await getUser();
    if (user == null) return null;
    final raw = user['id_familia'] ?? user['FamiliaID'];
    if (raw == null) return null;
    final id = raw is int ? raw : int.tryParse(raw.toString());
    return (id != null && id > 0) ? id : null;
  }

  Future<String> getUserRole() async {
    final user = await getUser();
    return (user?['nombre_rol'] ?? user?['rol'] ?? '').toString();
  }
}

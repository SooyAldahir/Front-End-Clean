import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/storage/session_storage.dart';
import '../../../shared/models/user.dart';

class AuthRepository {
  final ApiClient      _api     = ApiClient();
  final TokenStorage   _token   = TokenStorage();
  final SessionStorage _session = SessionStorage();

  Future<UserModel> login(String loginId, String password) async {
    final res = await _api.postJson(ApiEndpoints.login, data: {'login': loginId, 'password': password});
    if (res.statusCode >= 400) throw Exception('Credenciales inválidas');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = (data['session_token'] ?? data['token'] ?? '').toString();
    if (token.isEmpty) throw Exception('No se recibió session_token');

    await _token.save(token);
    await _session.saveSession(data, token);

    // Sincronizar FCM token
    await _syncFcm(data['id_usuario'] ?? data['IdUsuario']);

    return UserModel.fromJson(data);
  }

  Future<void> logout() async {
    try { await _api.postJson(ApiEndpoints.logout); } catch (_) {}
    await _token.clear();
    await _session.clear();
  }

  Future<void> resetPassword(String correo, String nuevaContrasena) async {
    final res = await _api.postJson(
      ApiEndpoints.resetPassword,
      data: {'correo': correo, 'nuevaContrasena': nuevaContrasena},
    );
    if (res.statusCode >= 400) throw Exception('No se pudo actualizar la contraseña');
  }

  Future<bool> isLoggedIn() async {
    final user = await _session.getUser();
    return user != null;
  }

  Future<void> _syncFcm(dynamic idUsuario) async {
    if (idUsuario == null) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      final lastSent = await _session.getLastFcmToken();
      if (lastSent == fcmToken) return;

      final res = await _api.putJson(
        ApiEndpoints.updateToken,
        data: {'id_usuario': idUsuario, 'fcm_token': fcmToken},
      );
      if (res.statusCode == 200) await _session.saveLastFcmToken(fcmToken);
    } catch (_) {}
  }
}

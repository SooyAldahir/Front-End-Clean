import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/family.dart';
import '../../../shared/models/search_result.dart';

class AdminRepository {
  final ApiClient _api = ApiClient();

  // ── Familias ──────────────────────────────────────────────────────────────
  Future<FamilyModel> createFamily({
    required String nombreFamilia,
    required String residencia,
    String? direccion,
    int? papaId,
    int? mamaId,
    List<int>? hijos,
  }) async {
    final payload = <String, dynamic>{
      'nombre_familia': nombreFamilia,
      'residencia':     residencia,
      if (direccion != null && direccion.trim().isNotEmpty) 'direccion': direccion.trim(),
      if (papaId  != null) 'papa_id': papaId,
      if (mamaId  != null) 'mama_id': mamaId,
      if (hijos   != null && hijos.isNotEmpty) 'hijos': hijos,
    };
    final res = await _api.postJson(ApiEndpoints.familias, data: payload);
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Error ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    final map = decoded is Map<String, dynamic>
        ? (decoded['data'] is Map ? Map<String, dynamic>.from(decoded['data'] as Map) : decoded)
        : decoded as Map<String, dynamic>;
    return FamilyModel.fromJson(map);
  }

  Future<List<dynamic>> getReporteCompleto() async {
    final res = await _api.getJson(ApiEndpoints.familiasReporte);
    if (res.statusCode >= 400) throw Exception('Error al obtener datos');
    return List<dynamic>.from(jsonDecode(res.body));
  }

  // ── Miembros ──────────────────────────────────────────────────────────────
  Future<void> addMember({required int idFamilia, required int idUsuario, required String tipoMiembro}) async {
    final res = await _api.postJson(ApiEndpoints.miembros, data: {
      'id_familia': idFamilia, 'id_usuario': idUsuario, 'tipo_miembro': tipoMiembro.toUpperCase(),
    });
    if (res.statusCode >= 400) throw Exception(jsonDecode(res.body)['error'] ?? 'Error');
  }

  Future<void> addMembersBulk({required int idFamilia, required List<int> idUsuarios}) async {
    final res = await _api.postJson(ApiEndpoints.miembrosBulk, data: {'id_familia': idFamilia, 'id_usuarios': idUsuarios});
    if (res.statusCode >= 400) throw Exception(jsonDecode(res.body)['error'] ?? 'Error');
  }

  Future<void> removeMember(int idMiembro) async {
    final res = await _api.deleteJson(ApiEndpoints.miembroById(idMiembro));
    if (res.statusCode >= 400) throw Exception('Error al eliminar miembro');
  }

  Future<List<dynamic>> getMiembrosByFamilia(int idFamilia) async {
    final res = await _api.getJson(ApiEndpoints.miembrosByFamilia(idFamilia));
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  // ── Usuarios ──────────────────────────────────────────────────────────────
  Future<void> registerExterno({required String nombre, required String apellido, required String email, required String contrasena, required int idRol}) async {
    final res = await _api.postJson(ApiEndpoints.usuarios, data: {
      'nombre': nombre, 'apellido': apellido, 'correo': email,
      'contrasena': contrasena, 'tipo_usuario': 'EXTERNO', 'id_rol': idRol,
    });
    if (res.statusCode >= 400) throw Exception(jsonDecode(res.body)['error'] ?? 'Error al registrar');
  }

  Future<List<dynamic>> searchUsers({String? q, String? tipo}) async {
    final res = await _api.getJson(ApiEndpoints.usuarios, query: {
      if (q    != null && q.isNotEmpty)    'q':    q,
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
    });
    if (res.statusCode >= 400) return [];
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final res = await _api.getJson(ApiEndpoints.usuarioById(id));
    if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
    return null;
  }

  Future<List<dynamic>> getCumpleaneros() async {
    final res = await _api.getJson(ApiEndpoints.cumpleanos);
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  Future<bool> updateFcmToken(int idUsuario, String fcmToken) async {
    try {
      final res = await _api.putJson(ApiEndpoints.updateToken, data: {'id_usuario': idUsuario, 'fcm_token': fcmToken});
      return res.statusCode == 200;
    } catch (_) { return false; }
  }
}

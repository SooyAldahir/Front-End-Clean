import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

class PerfilRepository {
  final ApiClient    _api   = ApiClient();
  final TokenStorage _token = TokenStorage();

  Future<Map<String, dynamic>?> getById(int id) async {
    final res = await _api.getJson(ApiEndpoints.usuarioById(id));
    if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
    return null;
  }

  Future<Map<String, dynamic>?> updateFoto(int id, String imagePath) async {
    final token = await _token.read();
    final stream = await _api.multipart(
      ApiEndpoints.usuarioById(id),
      method: 'PUT',
      files: [await http.MultipartFile.fromPath('foto', imagePath)],
      fields: {},
    );
    if (stream.statusCode == 200) {
      final body = await stream.stream.bytesToString();
      return Map<String, dynamic>.from(jsonDecode(body));
    }
    return null;
  }

  Future<List<dynamic>> getCatalogoEstados() async {
    final res = await _api.getJson(ApiEndpoints.estadosCatalogo);
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  Future<bool> updateEstado(int idUsuario, int idCatEstado) async {
    final res = await _api.postJson(ApiEndpoints.estados, data: {
      'id_usuario': idUsuario, 'id_cat_estado': idCatEstado, 'unico_vigente': true,
    });
    return res.statusCode == 201 || res.statusCode == 200;
  }
}

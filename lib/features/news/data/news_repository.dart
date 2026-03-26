import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class NewsRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getGlobalFeed({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _api.getJson(
        ApiEndpoints.feedGlobal,
        query: {'page': page, 'limit': limit},
      );
      if (res.statusCode == 200)
        return Map<String, dynamic>.from(jsonDecode(res.body));
      print('getGlobalFeed error \${res.statusCode}: \${res.body}');
    } catch (e) {
      print('getGlobalFeed exception: \$e');
    }
    return {
      'page': page,
      'limit': limit,
      'count': 0,
      'hasMore': false,
      'data': [],
    };
  }

  Future<Map<String, dynamic>> getFeedByFamilia(
    int idFamilia, {
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.getJson(
      '${ApiEndpoints.postsByFamilia(idFamilia)}?page=$page&limit=$limit',
    );
    if (res.statusCode == 200)
      return Map<String, dynamic>.from(jsonDecode(res.body));
    return {
      'page': page,
      'limit': limit,
      'count': 0,
      'hasMore': false,
      'data': [],
    };
  }

  Future<List<dynamic>> getPendientes(int idFamilia) async {
    final res = await _api.getJson(ApiEndpoints.postsPendientes(idFamilia));
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  Future<List<dynamic>> getMisPosts() async {
    final res = await _api.getJson(ApiEndpoints.misPosts);
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  Future<bool> crearPost({
    required int idUsuario,
    int? idFamilia,
    String? mensaje,
    File? imagen,
    String categoria = 'Familiar',
    String tipo = 'POST',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    final uri = Uri.parse('${ApiClient.baseUrl}${ApiEndpoints.publicaciones}');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['id_usuario'] = idUsuario.toString();
    request.fields['mensaje'] = mensaje ?? '';
    request.fields['categoria_post'] = categoria;
    request.fields['tipo'] = tipo;
    if (idFamilia != null) request.fields['id_familia'] = idFamilia.toString();
    if (imagen != null)
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagen.path),
      );

    final streamed = await request.send();
    return streamed.statusCode >= 200 && streamed.statusCode < 300;
  }

  Future<bool> responderSolicitud(int idPost, String estado) async {
    final res = await _api.putJson(
      ApiEndpoints.postEstado(idPost),
      data: {'estado': estado},
    );
    return res.statusCode == 200;
  }

  Future<void> toggleLike(int idPost) async {
    await _api.postJson(ApiEndpoints.postLike(idPost));
  }

  Future<List<dynamic>> getComentarios(int idPost) async {
    final res = await _api.getJson(ApiEndpoints.postComentarios(idPost));
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }

  Future<void> addComentario(int idPost, String contenido) async {
    await _api.postJson(
      ApiEndpoints.postComentarios(idPost),
      data: {'contenido': contenido},
    );
  }

  Future<void> deleteComentario(int idComentario) async {
    await _api.deleteJson(ApiEndpoints.comentarioById(idComentario));
  }

  Future<void> deletePost(int idPost) async {
    await _api.deleteJson(ApiEndpoints.postById(idPost));
  }
}

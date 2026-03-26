import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/family.dart';
import '../../../shared/models/search_result.dart';

class FamilyRepository {
  final ApiClient    _api   = ApiClient();
  final TokenStorage _token = TokenStorage();

  Future<FamilyModel?> getById(int id) async {
    final res = await _api.getJson(ApiEndpoints.familiaById(id));
    if (res.statusCode >= 400) return null;
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return FamilyModel.fromJson(data);
    return null;
  }

  Future<List<dynamic>> getAvailable() async {
    final res = await _api.getJson(ApiEndpoints.familiasAvailable);
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
    return [];
  }

  Future<List<Map<String, dynamic>>> searchByName(String q) async {
    final res = await _api.getJson(ApiEndpoints.familiasSearch, query: {'name': q});
    if (res.statusCode >= 400) return [];
    final data = jsonDecode(res.body);
    if (data is List) return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  Future<bool> updateFotos({required int familyId, File? profileImage, File? coverImage}) async {
    if (profileImage == null && coverImage == null) return false;
    final token = await _token.read();
    final req   = http.MultipartRequest('PATCH', Uri.parse('${ApiClient.baseUrl}${ApiEndpoints.familiaFotos(familyId)}'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (profileImage != null) req.files.add(await http.MultipartFile.fromPath('foto_perfil', profileImage.path));
    if (coverImage   != null) req.files.add(await http.MultipartFile.fromPath('foto_portada', coverImage.path));
    final response = await req.send();
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> updateDescripcion({required int familyId, required String descripcion}) async {
    final token = await _token.read();
    final req   = http.Request('PATCH', Uri.parse('${ApiClient.baseUrl}${ApiEndpoints.familiaDescripcion(familyId)}'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode({'descripcion': descripcion});
    final response = await req.send();
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<int?> resolveFamilyId({int? matricula, int? numEmpleado}) async {
    final query = <String, dynamic>{};
    if (matricula    != null) query['matricula']    = matricula;
    if (numEmpleado  != null) query['numEmpleado']  = numEmpleado;
    if (query.isEmpty) return null;

    final res = await _api.getJson(ApiEndpoints.familiasByDoc, query: query);
    if (res.statusCode >= 400) return null;
    final data = jsonDecode(res.body);
    final list = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
    if ((list as List).isEmpty) return null;
    return FamilyModel.fromJson(Map<String, dynamic>.from(list.first as Map)).id;
  }
}

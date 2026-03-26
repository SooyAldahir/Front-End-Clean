import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/search_result.dart';
import '../../chat/data/chat_repository.dart';

class SearchRepository {
  final ApiClient _api = ApiClient();

  Future<SearchResultModel> searchAll(String input) async {
    final q = input.trim();
    if (q.isEmpty) return const SearchResultModel();

    final isNumeric = RegExp(r'^\d+$').hasMatch(q);

    final futures = await Future.wait([
      _safeGet(ApiEndpoints.usuarios, query: {'tipo': 'ALUMNO',    'q': q}),
      _safeGet(ApiEndpoints.usuarios, query: {'tipo': 'EMPLEADO',  'q': q}),
      _safeGet(ApiEndpoints.usuarios, query: {'tipo': 'EXTERNO',   'q': q}),
      if (isNumeric) _safeGet(ApiEndpoints.familiasByDoc, query: {'matricula':   q}),
      if (isNumeric) _safeGet(ApiEndpoints.familiasByDoc, query: {'numEmpleado': q}),
      if (!isNumeric) _safeGet(ApiEndpoints.familiasSearch, query: {'name': q}),
    ]);

    final alumnos  = _parseUsers(futures[0]).where((u) => u.tipo.toUpperCase() == 'ALUMNO').toList();
    final empleados= _parseUsers(futures[1]).where((u) => u.tipo.toUpperCase() == 'EMPLEADO').toList();
    final externos = _parseUsers(futures[2]).where((u) => u.tipo.toUpperCase() == 'EXTERNO').toList();

    List<FamilyMiniModel> familias;
    if (isNumeric) {
      final a = _parseFamilies(futures[3]);
      final b = _parseFamilies(futures[4]);
      final map = <int, FamilyMiniModel>{};
      for (final f in [...a, ...b]) map[f.id] = f;
      familias = map.values.toList();
    } else {
      familias = _parseFamilies(futures[3]);
    }

    return SearchResultModel(alumnos: alumnos, empleados: empleados, familias: familias, externos: externos);
  }

  Future<dynamic> _safeGet(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _api.getJson(path, query: query);
      if (res.statusCode >= 400) return [];
      return jsonDecode(res.body);
    } catch (_) { return []; }
  }

  List<UserMiniModel> _parseUsers(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => UserMiniModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  List<FamilyMiniModel> _parseFamilies(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => FamilyMiniModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}

// ─── SearchViewModel ──────────────────────────────────────────────────────────
class SearchViewModel {
  final SearchRepository _repo    = SearchRepository();
  final ChatRepository   _chatRepo = ChatRepository();

  final loading  = ValueNotifier<bool>(false);
  final result   = ValueNotifier<SearchResultModel>(const SearchResultModel());
  bool _searched = false;
  bool get searched => _searched;

  Future<void> search(String q) async {
    if (q.trim().isEmpty) {
      result.value = const SearchResultModel();
      _searched = false;
      return;
    }
    loading.value = true;
    try {
      result.value = await _repo.searchAll(q);
      _searched = true;
    } catch (_) {
      result.value = const SearchResultModel();
    } finally {
      loading.value = false;
    }
  }

  Future<int?> initPrivateChat(int idUsuario) => _chatRepo.initPrivateChat(idUsuario);

  void dispose() { loading.dispose(); result.dispose(); }
}

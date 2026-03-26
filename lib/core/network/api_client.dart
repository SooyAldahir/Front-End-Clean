import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient extends http.BaseClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  // ── Cambia a prod comentando/descomentando ──────────────────────────────────
  static const String baseUrl = 'http://192.168.218.191:3000';
  // static const String baseUrl = 'https://edi301.apps.isdapps.uk';

  final http.Client _inner = http.Client();
  final Duration _timeout = const Duration(seconds: 20);

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('session_token');
    return (t != null && t.isNotEmpty) ? t : null;
  }

  Uri _resolve(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Uri.parse(url);
    }
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return Uri.parse('$base$path');
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _readToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    if (request is! http.MultipartRequest &&
        !request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }
    return _inner.send(request).timeout(_timeout);
  }

  Future<http.Response> getJson(String url, {Map<String, dynamic>? query}) {
    final uri = _resolve(url).replace(
      queryParameters: {...?query?.map((k, v) => MapEntry(k, v?.toString()))},
    );
    return get(uri).timeout(_timeout);
  }

  Future<http.Response> postJson(String url, {Object? data}) {
    return post(
      _resolve(url),
      headers: _jsonHeaders,
      body: data == null ? null : jsonEncode(data),
    ).timeout(_timeout);
  }

  Future<http.Response> putJson(String url, {Object? data}) {
    return put(
      _resolve(url),
      headers: _jsonHeaders,
      body: data == null ? null : jsonEncode(data),
    ).timeout(_timeout);
  }

  Future<http.Response> patchJson(String url, {Object? data}) {
    final req = http.Request('PATCH', _resolve(url));
    req.headers.addAll(_jsonHeaders);
    if (data != null) req.body = jsonEncode(data);
    return send(req).then(http.Response.fromStream).timeout(_timeout);
  }

  Future<http.Response> deleteJson(String url, {Object? data}) {
    if (data != null) {
      final req = http.Request('DELETE', _resolve(url));
      req.headers.addAll(_jsonHeaders);
      req.body = jsonEncode(data);
      return send(req).then(http.Response.fromStream);
    }
    return delete(_resolve(url)).timeout(_timeout);
  }

  Future<http.StreamedResponse> multipart(
    String url, {
    String method = 'POST',
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) {
    final req = http.MultipartRequest(method, _resolve(url));
    if (fields != null) req.fields.addAll(fields);
    if (files != null) req.files.addAll(files);
    return send(req);
  }
}

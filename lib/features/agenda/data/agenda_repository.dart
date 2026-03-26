import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

class EventoModel {
  final int idActividad;
  final String titulo;
  final String? descripcion;
  final DateTime fechaEvento;
  final String? horaEvento;
  final String? imagen;
  final String estadoPublicacion;
  final int? diasAnticipacion;

  const EventoModel({
    required this.idActividad,
    required this.titulo,
    this.descripcion,
    required this.fechaEvento,
    this.horaEvento,
    this.imagen,
    required this.estadoPublicacion,
    this.diasAnticipacion,
  });

  factory EventoModel.fromJson(Map<String, dynamic> j) => EventoModel(
        idActividad:       j['id_actividad'] ?? j['id_evento'] ?? 0,
        titulo:            j['titulo'] ?? '',
        descripcion:       j['descripcion'] ?? j['mensaje'],
        fechaEvento:       j['fecha_evento'] != null ? DateTime.parse(j['fecha_evento'].toString()) : DateTime.now(),
        horaEvento:        j['hora_evento']?.toString(),
        imagen:            j['imagen']?.toString(),
        estadoPublicacion: j['estado_publicacion'] ?? 'Publicada',
        diasAnticipacion:  j['dias_anticipacion'] as int?,
      );
}

class AgendaRepository {
  final ApiClient    _api   = ApiClient();
  final TokenStorage _token = TokenStorage();

  Future<List<EventoModel>> listar() async {
    final res = await _api.getJson(ApiEndpoints.agenda);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => EventoModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<bool> guardar({
    int? id,
    required String titulo,
    required DateTime fecha,
    String? hora,
    String? descripcion,
    File? imagenFile,
    int diasAnticipacion = 3,
  }) async {
    final endpoint = id == null ? ApiEndpoints.agenda : ApiEndpoints.agendaById(id);
    final method   = id == null ? 'POST' : 'PUT';

    final fields = <String, String>{
      'titulo':              titulo,
      'descripcion':         descripcion ?? '',
      'fecha_evento':        fecha.toIso8601String(),
      'hora_evento':         hora ?? '',
      'dias_anticipacion':   diasAnticipacion.toString(),
      'estado_publicacion':  'Publicada',
    };

    List<http.MultipartFile>? files;
    if (imagenFile != null) {
      files = [await http.MultipartFile.fromPath('imagen', imagenFile.path)];
    }

    final streamed = await _api.multipart(endpoint, method: method, fields: fields, files: files);
    final response = await http.Response.fromStream(streamed);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<void> eliminar(int id) async {
    await _api.deleteJson(ApiEndpoints.agendaById(id));
  }
}

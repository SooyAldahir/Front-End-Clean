import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../data/perfil_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../tools/media_picker.dart';

class PerfilViewModel {
  final PerfilRepository _repo    = PerfilRepository();
  final SessionStorage   _session = SessionStorage();

  final loading = ValueNotifier<bool>(true);
  final data    = ValueNotifier<Map<String, dynamic>>({
    'name': '—', 'matricula': '—', 'numEmpleado': '—', 'docLabel': 'Matrícula',
    'docValue': '—', 'phone': '—', 'email': '—', 'residence': '—',
    'family': '—', 'address': '—', 'birthday': '—', 'avatarUrl': '',
    'status': 'Activo', 'grade': '—',
  });

  bool _isAlumno = false;
  int? _userId;

  bool get isAlumno => _isAlumno;
  int? get userId   => _userId;

  Future<void> loadProfile() async {
    loading.value = true;
    await _hydrateFromLocal();
    await _fetchFromServer();
    loading.value = false;
  }

  Future<void> _hydrateFromLocal() async {
    final user = await _session.getUser();
    if (user == null) return;

    final tipo = (user['tipo_usuario'] ?? user['TipoUsuario'] ?? '').toString().toUpperCase();
    _isAlumno  = tipo == 'ALUMNO';
    _userId    = await _session.getUserId();

    final nombre   = (user['nombre']   ?? user['Nombre']   ?? '').toString();
    final apellido = (user['apellido'] ?? user['Apellido'] ?? '').toString();
    final matricula    = user['matricula']?.toString();
    final numEmpleado  = user['num_empleado']?.toString();
    String avatar = (user['foto_perfil'] ?? '').toString();
    if (avatar.isNotEmpty && !avatar.startsWith('http')) avatar = '${ApiClient.baseUrl}$avatar';

    data.value = {
      ...data.value,
      'name':       ('$nombre $apellido').trim().isEmpty ? '—' : ('$nombre $apellido').trim(),
      'email':      (user['correo'] ?? user['E_mail'] ?? '—').toString(),
      'matricula':  matricula ?? '—',
      'numEmpleado':numEmpleado ?? '—',
      'docLabel':   _isAlumno ? 'Matrícula' : 'No. Empleado',
      'docValue':   _isAlumno ? (matricula ?? '—') : (numEmpleado ?? '—'),
      'phone':      (user['telefono'] ?? '—').toString(),
      'residence':  (user['residencia'] ?? '—').toString(),
      'address':    (user['direccion'] ?? '—').toString(),
      'birthday':   _formatFecha(user['fecha_nacimiento']),
      'avatarUrl':  avatar,
      'status':     (user['estado'] ?? 'Activo').toString(),
      'grade':      (user['carrera'] ?? '—').toString(),
      'family':     (user['nombre_familia'] ?? '—').toString(),
    };
  }

  Future<void> _fetchFromServer() async {
    if (_userId == null) return;
    final x = await _repo.getById(_userId!);
    if (x == null) return;

    final nombre   = (x['nombre']   ?? '').toString();
    final apellido = (x['apellido'] ?? '').toString();
    String avatar  = (x['foto_perfil'] ?? '').toString();
    if (avatar.isNotEmpty && !avatar.startsWith('http')) avatar = '${ApiClient.baseUrl}$avatar';

    final tipo = (x['tipo_usuario'] ?? '').toString().toUpperCase();
    _isAlumno  = tipo == 'ALUMNO';
    final matricula   = x['matricula']?.toString();
    final numEmpleado = x['num_empleado']?.toString();

    data.value = {
      ...data.value,
      'name':           ('$nombre $apellido').trim().isEmpty ? data.value['name'] : ('$nombre $apellido').trim(),
      'email':          (x['correo'] ?? data.value['email']).toString(),
      'matricula':      matricula ?? '—',
      'numEmpleado':    numEmpleado ?? '—',
      'docLabel':       _isAlumno ? 'Matrícula' : 'No. Empleado',
      'docValue':       _isAlumno ? (matricula ?? '—') : (numEmpleado ?? '—'),
      'phone':          (x['telefono']    ?? data.value['phone']).toString(),
      'residence':      (x['residencia']  ?? data.value['residence']).toString(),
      'address':        (x['direccion']   ?? data.value['address']).toString(),
      'birthday':       _formatFecha(x['fecha_nacimiento'] ?? data.value['birthday']),
      'avatarUrl':      avatar.isNotEmpty ? avatar : data.value['avatarUrl'],
      'status':         (x['estado']      ?? data.value['status']).toString(),
      'statusColorHex': (x['color_estado'] ?? '#13436B').toString(),
      'grade':          (x['carrera']     ?? data.value['grade']).toString(),
      'family':         (x['nombre_familia'] ?? data.value['family']).toString(),
    };
  }

  Future<String?> pickAndUploadPhoto(BuildContext context) async {
    if (_userId == null) return 'No se pudo identificar el usuario';
    final image = await MediaPicker.pickImage(context);
    if (image == null) return null;

    loading.value = true;
    try {
      final updated = await _repo.updateFoto(_userId!, image.path);
      if (updated != null) await _fetchFromServer();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<List<dynamic>> getCatalogoEstados() => _repo.getCatalogoEstados();

  Future<String?> updateEstado(int idCatEstado) async {
    if (_userId == null) return 'Usuario no identificado';
    loading.value = true;
    try {
      final ok = await _repo.updateEstado(_userId!, idCatEstado);
      if (ok) await _fetchFromServer();
      return ok ? null : 'Error al actualizar estado';
    } finally {
      loading.value = false;
    }
  }

  String _formatFecha(dynamic raw) {
    if (raw == null || raw.toString().isEmpty || raw == '—') return '—';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString().split('T')[0];
    }
  }

  void dispose() { loading.dispose(); data.dispose(); }
}

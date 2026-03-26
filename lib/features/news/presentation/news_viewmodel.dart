import 'dart:io';
import 'package:flutter/material.dart';
import '../data/news_repository.dart';
import '../../../core/socket/socket_service.dart';
import '../../../core/storage/session_storage.dart';

class NewsViewModel {
  final NewsRepository _repo    = NewsRepository();
  final SocketService  _socket  = SocketService();
  final SessionStorage _session = SessionStorage();

  final posts       = ValueNotifier<List<dynamic>>([]);
  final loading     = ValueNotifier<bool>(true);
  final loadingMore = ValueNotifier<bool>(false);

  int     _currentPage = 1;
  bool    _hasMore     = true;
  int     _userId      = 0;
  int?    _familiaId;
  String  _userRole    = '';

  int    get userId    => _userId;
  int?   get familiaId => _familiaId;
  String get userRole  => _userRole;

  bool get isAlumnoRole => ['ALUMNO', 'HIJOEDI', 'HIJO', 'ESTUDIANTE'].contains(_userRole.trim().toUpperCase());
  bool get hasFamilia   => _familiaId != null && _familiaId! > 0;
  bool get canCreatePost => !(isAlumnoRole && !hasFamilia);

  Future<void> init() async {
    _userId    = await _session.getUserId()  ?? 0;
    _familiaId = await _session.getFamiliaId();
    _userRole  = await _session.getUserRole();
    _setupRealtime();
    await loadFeed();
  }

  void _setupRealtime() {
    _socket.initSocket();
    if (_userId > 0)    _socket.joinUserRoom(_userId);
    if (_familiaId != null) _socket.joinFamilyRoom(_familiaId!);
    _socket.joinInstitucionalRoom();

    for (final event in ['feed_actualizado', 'post_creado', 'post_eliminado', 'post_estado_actualizado', 'evento_creado', 'evento_actualizado', 'evento_eliminado']) {
      _socket.off(event);
      _socket.on(event, (_) => loadFeed());
    }
  }

  Future<void> loadFeed() async {
    loading.value    = true;
    _currentPage     = 1;
    _hasMore         = true;
    try {
      final resp = await _repo.getGlobalFeed(page: 1, limit: 50);
      posts.value  = List<dynamic>.from(resp['data'] ?? []);
      _hasMore     = resp['hasMore'] == true;
      _currentPage = 2;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loading.value || loadingMore.value || !_hasMore) return;
    loadingMore.value = true;
    try {
      final resp = await _repo.getGlobalFeed(page: _currentPage, limit: 50);
      final data = List<dynamic>.from(resp['data'] ?? []);
      posts.value = [...posts.value, ...data];
      _hasMore    = resp['hasMore'] == true;
      if (data.isNotEmpty) _currentPage++;
    } finally {
      loadingMore.value = false;
    }
  }

  void toggleLike(int index) async {
    final post     = posts.value[index];
    final isLiked  = post['is_liked'] == 1 || post['is_liked'] == true;
    final count    = int.tryParse(post['likes_count']?.toString() ?? '0') ?? 0;
    final updated  = List<dynamic>.from(posts.value);
    updated[index] = {...Map<String, dynamic>.from(post), 'is_liked': isLiked ? 0 : 1, 'likes_count': isLiked ? count - 1 : count + 1};
    posts.value    = updated;

    try {
      await _repo.toggleLike(post['id_post'] as int);
    } catch (_) {
      // revert
      final reverted = List<dynamic>.from(posts.value);
      reverted[index] = post;
      posts.value = reverted;
    }
  }

  Future<void> deletePost(int postId) async {
    await _repo.deletePost(postId);
    await loadFeed();
  }

  void dispose() {
    posts.dispose();
    loading.dispose();
    loadingMore.dispose();
  }
}

// ─── CreatePostViewModel ──────────────────────────────────────────────────────
class CreatePostViewModel {
  final NewsRepository _repo = NewsRepository();

  final mensajeCtrl = TextEditingController();
  final loading     = ValueNotifier<bool>(false);
  File? imagenSeleccionada;
  bool esAutoridad  = false;

  Future<void> init(String userRole) async {
    const rolesJefes = ['Admin', 'PapaEDI', 'MamaEDI', 'Padre', 'Madre', 'Tutor'];
    esAutoridad = rolesJefes.contains(userRole);
  }

  Future<String?> enviarPost({required int idUsuario, int? idFamilia}) async {
    if (mensajeCtrl.text.isEmpty && imagenSeleccionada == null) return 'Escribe algo o sube una foto';
    loading.value = true;
    try {
      final ok = await _repo.crearPost(
        idUsuario: idUsuario,
        idFamilia: idFamilia,
        mensaje:   mensajeCtrl.text,
        imagen:    imagenSeleccionada,
      );
      return ok ? null : 'Error al publicar';
    } catch (e) {
      return e.toString();
    } finally {
      loading.value = false;
    }
  }

  void dispose() {
    mensajeCtrl.dispose();
    loading.dispose();
  }
}

// ─── NotificationsViewModel ───────────────────────────────────────────────────
class NotificationsViewModel {
  final NewsRepository _repo    = NewsRepository();
  final SessionStorage _session = SessionStorage();
  final SocketService  _socket  = SocketService();

  final items    = ValueNotifier<List<dynamic>>([]);
  final loading  = ValueNotifier<bool>(true);

  bool   _esPadre   = false;
  int?   _userId;
  int?   _familiaId;

  bool get esPadre => _esPadre;

  Future<void> init() async {
    _userId    = await _session.getUserId();
    _familiaId = await _session.getFamiliaId();
    final rol  = await _session.getUserRole();
    _esPadre   = ['Admin','Padre','Madre','Tutor','PapaEDI','MamaEDI'].contains(rol);
    _setupRealtime();
    await loadData();
  }

  void _setupRealtime() {
    _socket.initSocket();
    if (_userId    != null) _socket.joinUserRoom(_userId!);
    if (_familiaId != null) _socket.joinFamilyRoom(_familiaId!);

    for (final e in ['post_pendiente_creado', 'post_estado_actualizado', 'mi_post_estado_actualizado']) {
      _socket.off(e);
      _socket.on(e, (_) => loadData());
    }
  }

  Future<void> loadData() async {
    loading.value = true;
    try {
      if (_esPadre && _familiaId != null) {
        items.value = await _repo.getPendientes(_familiaId!);
      } else {
        items.value = await _repo.getMisPosts();
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> procesar(int idPost, bool aprobar) async {
    final idx    = items.value.indexWhere((p) => p['id_post'] == idPost);
    final backup = idx != -1 ? items.value[idx] : null;
    items.value  = items.value.where((p) => p['id_post'] != idPost).toList();
    final ok = await _repo.responderSolicitud(idPost, aprobar ? 'Publicado' : 'Rechazada');
    if (!ok && backup != null) {
      final restored = List<dynamic>.from(items.value);
      restored.insert(idx, backup);
      items.value = restored;
    }
  }

  void dispose() {
    items.dispose();
    loading.dispose();
  }
}

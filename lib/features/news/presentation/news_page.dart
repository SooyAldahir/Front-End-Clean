import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../tools/fullscreen_image_viewer.dart';
import '../presentation/news_viewmodel.dart';
import 'create_post_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});
  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final NewsViewModel _vm = NewsViewModel();
  final _scrollCtrl = ScrollController();
  final Map<int, GlobalKey> _likeKeys = {};
  TapDownDetails? _lastDoubleTap;

  GlobalKey _likeKey(int id) => _likeKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    _vm.init();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 250) {
        _vm.loadMore();
      }
    });
  }

  @override
  void dispose() { _vm.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') return '';
    if (url.startsWith('http')) return url.contains('localhost') ? url.replaceFirst('http://localhost:3000', ApiClient.baseUrl) : url;
    return '${ApiClient.baseUrl}${url.startsWith('/') ? url : '/$url'}';
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr)?.toLocal();
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7)     return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays >= 1)    return 'Hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
    if (diff.inHours >= 1)   return 'Hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
    if (diff.inMinutes >= 1) return 'Hace ${diff.inMinutes} min';
    return 'Hace un momento';
  }

  Future<void> _animateHeart(int index, TapDownDetails details) async {
    final post    = _vm.posts.value[index];
    final postId  = post['id_post'] as int;
    final likeCtx = _likeKey(postId).currentContext;
    final isLiked = post['is_liked'] == 1 || post['is_liked'] == true;
    if (!isLiked) _vm.toggleLike(index);

    final overlay  = Overlay.of(context);
    final start    = details.globalPosition;
    final end      = likeCtx != null
        ? (likeCtx.findRenderObject() as RenderBox).localToGlobal(Offset.zero)
        : start;
    final anim = ValueNotifier<double>(0);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => IgnorePointer(child: ValueListenableBuilder<double>(
      valueListenable: anim,
      builder: (_, t, __) {
        final c  = Curves.easeInOutCubic.transform(t);
        final dx = lerpDouble(start.dx, end.dx, c)!;
        final dy = lerpDouble(start.dy, end.dy, c)!;
        return Stack(children: [Positioned(left: dx - 22, top: dy - 22,
          child: Transform.scale(scale: lerpDouble(1.35, 0.55, c)!, child: Opacity(opacity: lerpDouble(1.0, 0.75, c)!, child: const Icon(Icons.favorite, color: Colors.red, size: 44))))]);
      },
    )));
    overlay.insert(entry);
    for (int i = 0; i <= 56; i++) { if (!mounted) break; anim.value = i / 56; await Future.delayed(const Duration(milliseconds: 16)); }
    await Future.delayed(const Duration(milliseconds: 120));
    anim.dispose();
    if (entry.mounted) entry.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Noticias', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          ValueListenableBuilder<String>(
            valueListenable: ValueNotifier(_vm.userRole),
            builder: (_, __, ___) => IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications).then((_) => _vm.loadFeed()),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _vm.loading,
        builder: (_, loading, __) {
          if (loading) return const Center(child: CircularProgressIndicator());
          return ValueListenableBuilder<List<dynamic>>(
            valueListenable: _vm.posts,
            builder: (_, posts, __) => RefreshIndicator(
              onRefresh: _vm.loadFeed,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: posts.isEmpty ? 1 : posts.length + (_vm.loadingMore.value ? 1 : 0),
                itemBuilder: (_, index) {
                  if (posts.isEmpty) return _emptyState();
                  if (index == posts.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                  final item = posts[index];
                  if (item['tipo'] == 'EVENTO') return _eventCard(item);
                  return _postCard(item, index);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _vm.canCreatePost ? AppColors.accent : Colors.grey,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: _vm.canCreatePost ? () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => CreatePostPage(idUsuario: _vm.userId, idFamilia: _vm.familiaId),
        )).then((_) => _vm.loadFeed()) : null,
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.25),
    child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.newspaper, size: 80, color: Colors.grey),
      SizedBox(height: 20),
      Text('Aún no hay noticias.', style: TextStyle(fontSize: 18, color: Colors.grey)),
    ])),
  );

  Widget _eventCard(Map<String, dynamic> evento) {
    final fecha     = DateTime.tryParse(evento['fecha_evento'].toString());
    final fechaStr  = fecha != null ? '${fecha.day}/${fecha.month}' : '';
    final imagenUrl = evento['imagen'] ?? evento['url_imagen'];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppColors.accent, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
          decoration: const BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.vertical(top: Radius.circular(13))),
          child: Row(children: [
            const Icon(Icons.event_available), const SizedBox(width: 10),
            const Text('EVENTO PRÓXIMO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text(fechaStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (_vm.userRole == 'Admin') PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) { if (v == 'delete') _deleteEvent(evento['id_evento'] as int); },
              itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red)))],
            ),
          ]),
        ),
        if (imagenUrl != null && imagenUrl.toString().isNotEmpty)
          Container(height: 200, width: double.infinity, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(_fixUrl(imagenUrl.toString())), fit: BoxFit.cover))),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(evento['titulo'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(evento['mensaje'] ?? '', style: const TextStyle(fontSize: 16)),
        ])),
      ]),
    );
  }

  Widget _postCard(Map<String, dynamic> post, int index) {
    final nombre   = '${post['nombre']} ${post['apellido'] ?? ''}';
    final mensaje  = post['mensaje'] ?? '';
    final urlImg   = post['url_imagen'];
    final tiempo   = _timeAgo(post['created_at']?.toString());
    final esMio    = post['id_usuario'] == _vm.userId;
    final likes    = int.tryParse(post['likes_count']?.toString() ?? '0') ?? 0;
    final comments = int.tryParse(post['comentarios_count']?.toString() ?? '0') ?? 0;
    final isLiked  = post['is_liked'] == 1 || post['is_liked'] == true;
    final esCumple = post['tipo'] == 'CUMPLEAÑOS' || (mensaje.contains('🎂') && mensaje.contains('🎉'));
    final nomFam   = post['nombre_familia'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: esCumple ? 6 : 2,
      color: esCumple ? const Color(0xFFFFF8E1) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: esCumple ? const BorderSide(color: Colors.orangeAccent, width: 1.5) : BorderSide.none),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (esCumple) Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4), decoration: const BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
          child: const Text('🎉 ¡CELEBRACIÓN ESPECIAL! 🎉', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: esCumple ? Colors.orange : Colors.blue[100],
            backgroundImage: post['foto_perfil'] != null ? NetworkImage(_fixUrl(post['foto_perfil'])) : null,
            child: post['foto_perfil'] == null ? Text(nombre.isNotEmpty ? nombre[0] : 'U', style: const TextStyle(fontWeight: FontWeight.bold)) : null,
          ),
          title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (nomFam != null && nomFam.toString().isNotEmpty) Text('Con la $nomFam', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (tiempo.isNotEmpty) Text(tiempo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
          trailing: esMio ? PopupMenuButton<String>(
            onSelected: (v) { if (v == 'delete') _vm.deletePost(post['id_post'] as int); },
            itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Eliminar')]))],
          ) : (esCumple ? const Icon(Icons.cake, color: Colors.pink) : null),
        ),
        if (urlImg != null && urlImg.toString().isNotEmpty && urlImg != 'null')
          GestureDetector(
            onTap: () => FullScreenImageViewer.open(context, imageProvider: NetworkImage(_fixUrl(urlImg.toString())), heroTag: 'post_${post['id_post']}'),
            onDoubleTapDown: (d) => _lastDoubleTap = d,
            onDoubleTap: () { if (_lastDoubleTap != null) _animateHeart(index, _lastDoubleTap!); },
            child: Hero(tag: 'post_${post['id_post']}', child: Image.network(_fixUrl(urlImg.toString()), fit: BoxFit.cover, width: double.infinity,
              loadingBuilder: (_, child, progress) => progress == null ? child : Container(height: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
              errorBuilder: (_, __, ___) => Container(height: 150, color: Colors.grey[200], child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.broken_image, color: Colors.grey, size: 50), Text('Imagen no disponible', style: TextStyle(color: Colors.grey))])),
            )),
          ),
        if (mensaje.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Text(mensaje, style: const TextStyle(fontSize: 15))),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(children: [
          TextButton.icon(
            key: _likeKey(post['id_post'] as int),
            onPressed: () => _vm.toggleLike(index),
            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey[600]),
            label: Text(likes > 0 ? '$likes Likes' : 'Me gusta', style: TextStyle(color: isLiked ? Colors.red : Colors.grey[600])),
          ),
          const SizedBox(width: 15),
          TextButton.icon(
            onPressed: () => _showComments(post['id_post'] as int),
            icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
            label: Text(comments > 0 ? '$comments Comentarios' : 'Comentar', style: TextStyle(color: Colors.grey[600])),
          ),
        ])),
      ]),
    );
  }

  void _deleteEvent(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Eliminar Evento'),
      content: const Text('¿Eliminar este evento de la agenda?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red)))],
    ));
    if (ok == true) { await ApiClient().deleteJson('/api/agenda/$id'); _vm.loadFeed(); }
  }

  void _showComments(int postId) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _CommentsSheet(postId: postId, fixUrl: _fixUrl, currentUserId: _vm.userId, currentUserRole: _vm.userRole),
  );
}

// ─── CommentsSheet ─────────────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final int postId, currentUserId;
  final String currentUserRole;
  final String Function(String?) fixUrl;
  const _CommentsSheet({required this.postId, required this.fixUrl, required this.currentUserId, required this.currentUserRole});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  final _repo = _CommentsRepo();
  List<dynamic> _comments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final list = await _repo.getComentarios(widget.postId);
    if (mounted) setState(() { _comments = list; _loading = false; });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await _repo.addComentario(widget.postId, text);
    _load();
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Eliminar comentario'),
      content: const Text('¿Deseas borrar este comentario?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red)))],
    ));
    if (ok == true) { await _repo.deleteComentario(id); _load(); }
  }

  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.75,
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    child: Column(children: [
      Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
      const Text('Comentarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const Divider(),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _comments.isEmpty ? const Center(child: Text('Sé el primero en comentar 👇')) :
        ListView.builder(itemCount: _comments.length, itemBuilder: (_, i) {
          final c     = _comments[i];
          final nombre= '${c['nombre']} ${c['apellido'] ?? ''}';
          final puede = c['id_usuario'] == widget.currentUserId || ['Admin','PapaEDI','MamaEDI'].contains(widget.currentUserRole);
          return ListTile(
            leading: CircleAvatar(radius: 18, backgroundImage: c['foto_perfil'] != null ? NetworkImage(widget.fixUrl(c['foto_perfil'])) : null, child: c['foto_perfil'] == null ? Text(nombre[0]) : null),
            title: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2), Text(c['contenido'], style: const TextStyle(fontSize: 14)),
            ])),
            trailing: puede ? IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey), onPressed: () => _delete(c['id_comentario'] as int)) : null,
          );
        }),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10, left: 10, right: 10, top: 5),
        child: Row(children: [
          Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Escribe un comentario...', fillColor: Colors.grey[200], filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)))),
          const SizedBox(width: 8),
          CircleAvatar(backgroundColor: AppColors.primary, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _send)),
        ]),
      ),
    ]),
  );
}

class _CommentsRepo {
  final _api = ApiClient();
  Future<List<dynamic>> getComentarios(int id) async {
    final res = await _api.getJson('/api/publicaciones/$id/comentarios');
    if (res.statusCode == 200) return List<dynamic>.from(jsonDecode(res.body));
    return [];
  }
  Future<void> addComentario(int id, String contenido) => _api.postJson('/api/publicaciones/$id/comentarios', data: {'contenido': contenido});
  Future<void> deleteComentario(int id) => _api.deleteJson('/api/publicaciones/comentarios/$id');
}

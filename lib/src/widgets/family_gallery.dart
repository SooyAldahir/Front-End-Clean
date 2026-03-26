import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/socket/socket_service.dart';

class FamilyGallery extends StatefulWidget {
  final int idFamilia;
  const FamilyGallery({super.key, required this.idFamilia});
  @override
  State<FamilyGallery> createState() => _FamilyGalleryState();
}

class _FamilyGalleryState extends State<FamilyGallery> {
  final SocketService _socket = SocketService();
  final ApiClient     _http   = ApiClient();
  List<dynamic> _fotos  = [];
  bool          _loading = true;

  @override
  void initState() { super.initState(); _cargarFotos(); }

  Future<void> _cargarFotos() async {
    final res = await _http.getJson('/api/fotos/familia/${widget.idFamilia}');
    if (mounted) setState(() {
      _fotos   = res.statusCode == 200 ? List<dynamic>.from(jsonDecode(res.body)) : [];
      _loading = false;
    });
  }

  String _absUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return '${ApiClient.baseUrl}${raw.startsWith('/') ? raw : '/$raw'}';
  }

  void _abrirVisor(int index) => Navigator.push(context, MaterialPageRoute(
    builder: (_) => _FullScreenViewer(fotos: _fotos, initialIndex: index),
  ));

  @override
  void dispose() {
    if (_socket.isReady) _socket.off('foto_agregada');
    _socket.leaveRoom('familia_${widget.idFamilia}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_fotos.isEmpty) return Container(
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 10),
        const Text('Aún no hay fotos en la familia', style: TextStyle(color: Colors.grey, fontSize: 16)),
      ]),
    );
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 1.0),
      itemCount: _fotos.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _abrirVisor(i),
        child: Image.network(_absUrl(_fotos[i]['url_imagen'] ?? ''), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey))),
      ),
    );
  }
}

class _FullScreenViewer extends StatefulWidget {
  final List<dynamic> fotos;
  final int initialIndex;
  const _FullScreenViewer({required this.fotos, required this.initialIndex});
  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() { super.initState(); _current = widget.initialIndex; _pageCtrl = PageController(initialPage: widget.initialIndex); }

  String _absUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    return '${ApiClient.baseUrl}${raw.startsWith('/') ? raw : '/$raw'}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white),
      title: Text('${_current + 1} / ${widget.fotos.length}', style: const TextStyle(color: Colors.white))),
    body: PageView.builder(
      controller: _pageCtrl, itemCount: widget.fotos.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (_, i) => Center(child: InteractiveViewer(child: Image.network(_absUrl(widget.fotos[i]['url_imagen'] ?? ''), fit: BoxFit.contain))),
    ),
  );
}

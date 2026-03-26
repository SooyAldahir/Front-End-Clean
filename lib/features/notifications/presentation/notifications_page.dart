import 'package:flutter/material.dart';
import '../../news/presentation/news_viewmodel.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsViewModel _vm = NotificationsViewModel();

  @override
  void initState() { super.initState(); _vm.init(); }
  @override
  void dispose() { _vm.dispose(); super.dispose(); }

  String _absUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return '${ApiClient.baseUrl}$raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<List<dynamic>>(
          valueListenable: _vm.items,
          builder: (_, __, ___) => Text(_vm.esPadre ? 'Solicitudes Pendientes' : 'Mis Publicaciones'),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _vm.loading,
          builder: (_, loading, __) {
            if (loading) return const Center(child: CircularProgressIndicator());
            return ValueListenableBuilder<List<dynamic>>(
              valueListenable: _vm.items,
              builder: (_, items, __) {
                if (items.isEmpty) return _emptyState();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _vm.esPadre ? _approverCard(items[i]) : _statusCard(items[i]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(_vm.esPadre ? Icons.check_circle_outline : Icons.history, size: 80, color: Colors.grey[300]),
    const SizedBox(height: 16),
    Text(_vm.esPadre ? '¡Todo al día!' : 'Sin actividad reciente', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
  ]));

  Widget _approverCard(Map<String, dynamic> item) {
    final url = _absUrl(item['url_imagen']?.toString());
    return Card(
      elevation: 3, margin: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        ListTile(
          leading: CircleAvatar(backgroundColor: AppColors.primary,
            child: Text((item['nombre'] ?? '?').toString().isNotEmpty ? item['nombre'].toString()[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))),
          title: Text('${item['nombre']} ${item['apellido']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item['mensaje'] ?? 'Solicita publicar esto...'),
          trailing: Text(item['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        if (url.isNotEmpty) Container(height: 250, width: double.infinity, color: Colors.black12,
          child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 40))),
        Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton.icon(
            onPressed: () => _vm.procesar(item['id_post'] as int, false),
            icon: const Icon(Icons.close, color: Colors.white), label: const Text('Rechazar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: () => _vm.procesar(item['id_post'] as int, true),
            icon: const Icon(Icons.check, color: Colors.white), label: const Text('Aprobar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
          ),
        ])),
      ]),
    );
  }

  Widget _statusCard(Map<String, dynamic> item) {
    final estado = item['estado']?.toString() ?? '';
    final Color  color;
    final IconData icon;
    if (estado == 'Publicado' || estado == 'Aprobada') { color = Colors.green;  icon = Icons.check_circle; }
    else if (estado == 'Rechazada')                    { color = Colors.red;    icon = Icons.cancel; }
    else                                               { color = Colors.orange; icon = Icons.hourglass_top; }

    final url = _absUrl(item['url_imagen']?.toString());
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text('Estado: $estado', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        subtitle: Text(item['mensaje'] ?? 'Sin descripción'),
        trailing: Text(item['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 12)),
      ),
      if (url.isNotEmpty) Container(height: 200, width: double.infinity, color: Colors.grey[200],
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)))),
      const SizedBox(height: 10),
    ]));
  }
}

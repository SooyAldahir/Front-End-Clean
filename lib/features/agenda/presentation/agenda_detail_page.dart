import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/network/api_client.dart';
import '../../agenda/data/agenda_repository.dart';

class AgendaDetailPage extends StatelessWidget {
  final EventoModel evento;
  const AgendaDetailPage({super.key, required this.evento});

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String _formatTime(String? t) { if (t == null || t.isEmpty) return 'Todo el día'; return t.length > 5 ? t.substring(0, 5) : t; }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Eliminar Evento'),
      content: const Text('¿Seguro que deseas eliminar esta actividad?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red)))],
    ));
    if (ok == true) {
      await ApiClient().deleteJson('/api/agenda/${evento.idActividad}');
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _edit(BuildContext context) async {
    final map = {'id_evento': evento.idActividad, 'titulo': evento.titulo, 'mensaje': evento.descripcion, 'fecha_evento': evento.fechaEvento.toIso8601String(), 'dias_anticipacion': evento.diasAnticipacion ?? 3};
    final result = await Navigator.pushNamed(context, AppRoutes.crearEvento, arguments: map);
    if (result == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(evento.titulo), backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        actions: [
          IconButton(tooltip: 'Editar',   icon: const Icon(Icons.edit),   onPressed: () => _edit(context)),
          IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete), onPressed: () => _delete(context)),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (evento.imagen != null && evento.imagen!.startsWith('http'))
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(evento.imagen!, height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[200]))),
            const SizedBox(height: 16),
            Text(evento.titulo, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _InfoTile(icon: Icons.calendar_today, label: 'Fecha',    value: _formatDate(evento.fechaEvento)),
            _InfoTile(icon: Icons.access_time,    label: 'Hora',     value: _formatTime(evento.horaEvento)),
            if (evento.diasAnticipacion != null)
              _InfoTile(icon: Icons.notifications_active, label: 'Avisar desde', value: '${evento.diasAnticipacion} días antes'),
            const Divider(height: 32),
            _InfoTile(icon: Icons.description_outlined, label: 'Descripción', value: (evento.descripcion == null || evento.descripcion!.isEmpty) ? 'No hay descripción.' : evento.descripcion!),
          ]),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.grey[700], size: 24), const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SelectableText(value, style: Theme.of(context).textTheme.bodyLarge),
      ])),
    ]),
  );
}

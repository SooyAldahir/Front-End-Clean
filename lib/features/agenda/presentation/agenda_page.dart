import 'package:flutter/material.dart';
import 'agenda_viewmodel.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../agenda/data/agenda_repository.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});
  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final AgendaViewModel _vm = AgendaViewModel();

  @override
  void initState() { super.initState(); _vm.init(); }
  @override
  void dispose() { _vm.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Agenda'), backgroundColor: AppColors.primary),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _vm.loading,
          builder: (_, loading, __) {
            if (loading) return const Center(child: CircularProgressIndicator());
            return ValueListenableBuilder<List<EventoModel>>(
              valueListenable: _vm.eventos,
              builder: (_, eventos, __) {
                if (eventos.isEmpty) return const Center(child: Text('No hay eventos programados.'));
                return ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (_, i) {
                    final e = eventos[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(e.fechaEvento.day.toString())),
                      title: Text(e.titulo),
                      subtitle: Text('${e.fechaEvento.year}/${e.fechaEvento.month}/${e.fechaEvento.day} · ${e.horaEvento ?? 'Todo el día'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.pushNamed(context, AppRoutes.agendaDetail, arguments: e);
                        if (result == true) _vm.load();
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.crearEvento);
          if (result == true) _vm.load();
        },
      ),
    );
  }
}

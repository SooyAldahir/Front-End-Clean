import 'dart:io';
import 'package:flutter/material.dart';
import '../data/agenda_repository.dart';
import '../../../core/socket/socket_service.dart';
import '../../../tools/media_picker.dart';
import '../../../tools/generic_reminders.dart' as reminders_tool;

class AgendaViewModel {
  final AgendaRepository _repo   = AgendaRepository();
  final SocketService    _socket = SocketService();

  final eventos = ValueNotifier<List<EventoModel>>([]);
  final loading = ValueNotifier<bool>(true);

  Future<void> init() async {
    _socket.initSocket();
    _socket.joinInstitucionalRoom();
    for (final e in ['evento_creado', 'evento_actualizado', 'evento_eliminado']) {
      _socket.off(e);
      _socket.on(e, (_) => load());
    }
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    try { eventos.value = await _repo.listar(); }
    finally { loading.value = false; }
  }

  Future<void> eliminar(int id) async {
    await _repo.eliminar(id);
    await load();
  }

  void dispose() {
    eventos.dispose();
    loading.dispose();
  }
}

// ─── CreateEventViewModel ─────────────────────────────────────────────────────
class CreateEventViewModel {
  final AgendaRepository _repo = AgendaRepository();

  final tituloCtrl               = TextEditingController();
  final descCtrl                 = TextEditingController();
  final recordatorioDiasCtrl     = TextEditingController(text: '3');
  final loading                  = ValueNotifier<bool>(false);
  final crearRecordatorio        = ValueNotifier<bool>(false);

  File?      imagenSeleccionada;
  String?    imagenUrlRemota;
  DateTime?  fechaEvento;
  TimeOfDay? horaEvento;
  int?       _idEvento;

  void initFromEvento(Map<String, dynamic>? evento) {
    if (evento == null) {
      fechaEvento = DateTime.now().add(const Duration(days: 1));
      return;
    }
    _idEvento = evento['id_evento'] ?? evento['id_actividad'];
    tituloCtrl.text = evento['titulo'] ?? '';
    descCtrl.text   = evento['mensaje'] ?? evento['descripcion'] ?? '';
    recordatorioDiasCtrl.text = (evento['dias_anticipacion'] ?? 3).toString();
    imagenUrlRemota = evento['imagen'];
    if (evento['fecha_evento'] != null) fechaEvento = DateTime.tryParse(evento['fecha_evento'].toString());
    fechaEvento ??= DateTime.now();
    if (evento['hora_evento'] != null) {
      final parts = evento['hora_evento'].toString().split(':');
      if (parts.length >= 2) horaEvento = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  Future<String?> guardar() async {
    if (fechaEvento == null) return 'Selecciona una fecha';
    loading.value = true;
    try {
      final ok = await _repo.guardar(
        id:                _idEvento,
        titulo:            tituloCtrl.text,
        fecha:             fechaEvento!,
        hora:              horaEvento != null ? '${horaEvento!.hour.toString().padLeft(2,'0')}:${horaEvento!.minute.toString().padLeft(2,'0')}' : null,
        descripcion:       descCtrl.text,
        imagenFile:        imagenSeleccionada,
        diasAnticipacion:  int.tryParse(recordatorioDiasCtrl.text) ?? 3,
      );
      if (!ok) return 'Error al guardar el evento';

      if (crearRecordatorio.value) await _crearRecordatorio();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }

  Future<void> _crearRecordatorio() async {
    try {
      final dias      = int.tryParse(recordatorioDiasCtrl.text) ?? 1;
      final fechaFin  = fechaEvento!;
      final fechaInicio = fechaFin.subtract(Duration(days: dias));
      final hora = horaEvento != null
          ? '${horaEvento!.hour.toString().padLeft(2,'0')}:${horaEvento!.minute.toString().padLeft(2,'0')}:00'
          : '13:00:00';

      await reminders_tool.createReminder(
        title:                tituloCtrl.text,
        description:          descCtrl.text,
        start_date:           fechaInicio.toIso8601String().split('T').first,
        end_date:             fechaFin.toIso8601String().split('T').first,
        time_of_day:          hora,
        repeat_interval_unit: reminders_tool.RepeatIntervalUnit.DAY,
        repeat_every_n:       1,
      );
    } catch (_) {}
  }

  Future<void> pickImage(BuildContext context) async {
    final f = await MediaPicker.pickImage(context);
    if (f != null) imagenSeleccionada = File(f.path);
  }

  void dispose() {
    tituloCtrl.dispose();
    descCtrl.dispose();
    recordatorioDiasCtrl.dispose();
    loading.dispose();
    crearRecordatorio.dispose();
  }
}

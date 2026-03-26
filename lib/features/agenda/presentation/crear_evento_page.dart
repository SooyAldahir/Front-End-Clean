import 'package:flutter/material.dart';
import 'agenda_viewmodel.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class CreateEventPage extends StatefulWidget {
  final Map<String, dynamic>? eventoExistente;
  const CreateEventPage({super.key, this.eventoExistente});
  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final CreateEventViewModel _vm = CreateEventViewModel();

  @override
  void initState() { super.initState(); _vm.initFromEvento(widget.eventoExistente); }
  @override
  void dispose() { _vm.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _vm.fechaEvento ?? now, firstDate: DateTime(2020), lastDate: DateTime(now.year + 5));
    if (picked != null) setState(() => _vm.fechaEvento = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _vm.horaEvento ?? TimeOfDay.now());
    if (picked != null) setState(() => _vm.horaEvento = picked);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.eventoExistente != null;
    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Evento' : 'Nuevo Evento'), backgroundColor: AppColors.primary, iconTheme: const IconThemeData(color: Colors.white), titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20)),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _vm.loading,
          builder: (_, loading, __) {
            if (loading) return const Center(child: CircularProgressIndicator());
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(children: [
                // Imagen
                GestureDetector(
                  onTap: () async { await _vm.pickImage(context); setState(() {}); },
                  child: Container(
                    height: 200, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400),
                      image: _vm.imagenSeleccionada != null ? DecorationImage(image: FileImage(_vm.imagenSeleccionada!), fit: BoxFit.cover)
                          : (_vm.imagenUrlRemota != null && _vm.imagenUrlRemota!.isNotEmpty) ? DecorationImage(image: NetworkImage('${ApiClient.baseUrl}${_vm.imagenUrlRemota}'), fit: BoxFit.cover) : null),
                    child: (_vm.imagenSeleccionada == null && (_vm.imagenUrlRemota == null || _vm.imagenUrlRemota!.isEmpty))
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 50, color: Colors.grey), SizedBox(height: 10), Text('Toca para agregar imagen', style: TextStyle(color: Colors.grey))]) : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(controller: _vm.tituloCtrl, decoration: const InputDecoration(labelText: 'Título del Evento', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
                const SizedBox(height: 15),
                TextField(controller: _vm.descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description))),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(child: ListTile(
                    title: Text(_vm.fechaEvento == null ? 'Fecha' : '${_vm.fechaEvento!.day}/${_vm.fechaEvento!.month}/${_vm.fechaEvento!.year}'),
                    trailing: const Icon(Icons.calendar_today), onTap: _pickDate,
                    tileColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade400)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ListTile(
                    title: Text(_vm.horaEvento == null ? 'Hora' : _vm.horaEvento!.format(context)),
                    trailing: const Icon(Icons.access_time), onTap: _pickTime,
                    tileColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade400)),
                  )),
                ]),
                const SizedBox(height: 15),
                TextField(controller: _vm.recordatorioDiasCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Días de anticipación', helperText: 'Días antes para mostrar en el feed.', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer))),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    final err = await _vm.guardar();
                    if (!mounted) return;
                    if (err != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red)); return; }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(esEdicion ? 'Evento actualizado' : 'Evento creado con éxito'), backgroundColor: Colors.green));
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(esEdicion ? 'Guardar Cambios' : 'Publicar Evento', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

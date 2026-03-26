import 'dart:io';
import 'package:flutter/material.dart';
import '../presentation/news_viewmodel.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../tools/media_picker.dart';

class CreatePostPage extends StatefulWidget {
  final int idUsuario;
  final int? idFamilia;
  const CreatePostPage({super.key, required this.idUsuario, this.idFamilia});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final CreatePostViewModel _vm = CreatePostViewModel();

  @override
  void initState() {
    super.initState();
    // role will be refreshed from session in a real app; passed via parent
    _vm.esAutoridad = false; // default; real value comes from session
  }

  @override
  void dispose() { _vm.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final f = await MediaPicker.pickImage(context);
    if (f != null) setState(() => _vm.imagenSeleccionada = File(f.path));
  }

  Future<void> _send() async {
    final err = await _vm.enviarPost(idUsuario: widget.idUsuario, idFamilia: widget.idFamilia);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_vm.esAutoridad ? '¡Publicado correctamente! 🎉' : 'Publicación enviada a aprobación ⏳'),
      backgroundColor: _vm.esAutoridad ? Colors.green : Colors.orange,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Publicación'), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              controller: _vm.mensajeCtrl, maxLines: 5,
              decoration: InputDecoration(hintText: '¿Qué quieres compartir hoy?', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[100]),
            ),
            const SizedBox(height: 20),
            if (_vm.imagenSeleccionada != null)
              Stack(alignment: Alignment.topRight, children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_vm.imagenSeleccionada!, height: 250, width: double.infinity, fit: BoxFit.cover)),
                GestureDetector(
                  onTap: () => setState(() => _vm.imagenSeleccionada = null),
                  child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white)),
                ),
              ]),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _pickImage, icon: const Icon(Icons.photo_library), label: const Text('Agregar Foto'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 30),
            ValueListenableBuilder<bool>(
              valueListenable: _vm.loading,
              builder: (_, loading, __) => ElevatedButton(
                onPressed: loading ? null : _send,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: _vm.esAutoridad ? Colors.green[600] : Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_vm.esAutoridad ? 'PUBLICAR AHORA' : 'ENVIAR A APROBACIÓN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

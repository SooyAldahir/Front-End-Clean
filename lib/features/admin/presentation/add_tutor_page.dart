import 'package:flutter/material.dart';
import 'admin_viewmodels.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/app_widgets.dart';

class AddTutorPage extends StatefulWidget {
  const AddTutorPage({super.key});
  @override
  State<AddTutorPage> createState() => _AddTutorPageState();
}

class _AddTutorPageState extends State<AddTutorPage> {
  final AddTutorViewModel _vm = AddTutorViewModel();
  @override
  void dispose() { _vm.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Tutor Externo'), backgroundColor: AppColors.primary),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Registra a un padre o madre que no cuenta con correo institucional.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            const Text('Relación:', style: TextStyle(fontWeight: FontWeight.bold)),
            ValueListenableBuilder<int>(
              valueListenable: _vm.idRol,
              builder: (_, rol, __) => Row(children: [
                Expanded(child: RadioListTile<int>(title: const Text('Papá EDI'), value: 2, groupValue: rol, onChanged: (v) => _vm.idRol.value = v!, contentPadding: EdgeInsets.zero)),
                Expanded(child: RadioListTile<int>(title: const Text('Mamá EDI'), value: 3, groupValue: rol, onChanged: (v) => _vm.idRol.value = v!, contentPadding: EdgeInsets.zero)),
              ]),
            ),
            const SizedBox(height: 10),
            TextField(controller: _vm.nombreCtrl,   decoration: const InputDecoration(labelText: 'Nombre(s)',                    prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),
            TextField(controller: _vm.apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellidos',                    prefixIcon: Icon(Icons.badge))),
            const SizedBox(height: 15),
            TextField(controller: _vm.correoCtrl,   decoration: const InputDecoration(labelText: 'Correo electrónico personal',  prefixIcon: Icon(Icons.email), hintText: 'ejemplo@gmail.com'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 15),
            TextField(controller: _vm.contrasenaCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña temporal', prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 30),
            ValueListenableBuilder<bool>(
              valueListenable: _vm.loading,
              builder: (_, loading, __) => ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                label: Text(loading ? 'Guardando...' : 'Crear Tutor', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: loading ? null : () async {
                  final err = await _vm.save();
                  if (!mounted) return;
                  if (err != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red)); return; }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutor externo registrado con éxito'), backgroundColor: Colors.green));
                  Navigator.pop(context);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

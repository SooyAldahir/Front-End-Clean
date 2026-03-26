import 'package:flutter/material.dart';
import 'admin_viewmodels.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/models/search_result.dart';

class AddFamilyPage extends StatefulWidget {
  const AddFamilyPage({super.key});
  @override
  State<AddFamilyPage> createState() => _AddFamilyPageState();
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  final AddFamilyViewModel _vm   = AddFamilyViewModel();
  final _childSearchCtrl         = TextEditingController();

  @override
  void dispose() { _childSearchCtrl.dispose(); _vm.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Familia'), backgroundColor: AppColors.primary),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // Nombre calculado
            ValueListenableBuilder<String>(
              valueListenable: _vm.familyName,
              builder: (_, name, __) => ListTile(leading: const Icon(Icons.family_restroom), title: const Text('Nombre de la familia'), subtitle: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 8),
            _employeeSearch(label: 'Papá (empleado)', ctrl: _vm.fatherCtrl, onChanged: (v) => _vm.searchEmployee(v, isFather: true), results: _vm.fatherResults, onPick: _vm.pickFather),
            const SizedBox(height: 8),
            _employeeSearch(label: 'Mamá (empleado)', ctrl: _vm.motherCtrl, onChanged: (v) => _vm.searchEmployee(v, isFather: false), results: _vm.motherResults, onPick: _vm.pickMother),
            const SizedBox(height: 12),
            // Residencia
            ValueListenableBuilder<bool>(
              valueListenable: _vm.internalResidence,
              builder: (_, internal, __) => Column(children: [
                SwitchListTile.adaptive(value: internal, onChanged: (v) => _vm.internalResidence.value = v, title: const Text('Residencia interna')),
                if (!internal) TextField(controller: _vm.addressCtrl, decoration: const InputDecoration(labelText: 'Dirección (requerida si es Externa)', prefixIcon: Icon(Icons.home_outlined))),
              ]),
            ),
            const Divider(height: 32),
            const Text('Hijos sanguíneos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _childSearchCtrl, decoration: const InputDecoration(labelText: 'Buscar alumno por nombre o matrícula', prefixIcon: Icon(Icons.search)), onChanged: _vm.searchChild),
            ValueListenableBuilder<List<UserMiniModel>>(
              valueListenable: _vm.childResults,
              builder: (_, list, __) => Column(children: list.take(5).map((u) => ListTile(dense: true, leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(u.fullName), subtitle: Text(u.matricula != null ? 'Matrícula: ${u.matricula}' : ''), trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _vm.addChild(u))))).toList()),
            ),
            ValueListenableBuilder<List<UserMiniModel>>(
              valueListenable: _vm.children,
              builder: (_, kids, __) => Wrap(spacing: 6, runSpacing: -8, children: kids.asMap().entries.map((e) => Chip(label: Text(e.value.fullName), deleteIcon: const Icon(Icons.close), onDeleted: () => setState(() => _vm.removeChild(e.key)))).toList()),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<bool>(
              valueListenable: _vm.loading,
              builder: (_, loading, __) => ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(loading ? 'Guardando...' : 'Guardar'),
                onPressed: loading ? null : () async {
                  final err = await _vm.save(context);
                  if (!mounted) return;
                  if (err != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))); return; }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Familia creada con éxito')));
                  Navigator.pop(context, true);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _employeeSearch({required String label, required TextEditingController ctrl, required Function(String) onChanged, required ValueNotifier<List<UserMiniModel>> results, required Function(UserMiniModel) onPick}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: ctrl, decoration: InputDecoration(labelText: '$label (por nombre o No. empleado)', prefixIcon: const Icon(Icons.search)), onChanged: onChanged),
      ValueListenableBuilder<List<UserMiniModel>>(
        valueListenable: results,
        builder: (_, list, __) => Column(children: list.take(5).map((u) => ListTile(dense: true, leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(u.fullName), subtitle: Text(u.numEmpleado != null ? 'Empleado: ${u.numEmpleado}' : (u.email ?? '')), trailing: IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: () => onPick(u)))).toList()),
      ),
    ]);
}

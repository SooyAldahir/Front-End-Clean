import 'package:flutter/material.dart';
import 'admin_viewmodels.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/models/search_result.dart';
import '../../../shared/models/family.dart';
import '../../family/data/family_repository.dart';

class AddAlumnsPage extends StatefulWidget {
  const AddAlumnsPage({super.key});
  @override
  State<AddAlumnsPage> createState() => _AddAlumnsPageState();
}

class _AddAlumnsPageState extends State<AddAlumnsPage> {
  final AddAlumnsViewModel _vm      = AddAlumnsViewModel();
  final _familyRepo                 = FamilyRepository();
  final _alumnSearchCtrl            = TextEditingController();

  @override
  void initState() { super.initState(); }
  @override
  void dispose() { _vm.dispose(); _alumnSearchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Alumnos a Familia'), backgroundColor: AppColors.primary),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Family selector
              ValueListenableBuilder<FamilyModel?>(
                valueListenable: _vm.selectedFamily,
                builder: (_, selectedFamily, __) => Autocomplete<FamilyModel>(
                  displayStringForOption: (f) => f.familyName,
                  optionsBuilder: (val) {
                    if (selectedFamily != null) return const Iterable<FamilyModel>.empty();
                    return _familyRepo.searchByName(val.text).then((list) => list.map((m) => FamilyModel.fromJson(m)));
                  },
                  onSelected: (f) { _vm.selectedFamily.value = f; FocusScope.of(context).unfocus(); },
                  fieldViewBuilder: (_, textCtrl, focusNode, __) {
                    if (selectedFamily != null) textCtrl.text = selectedFamily.familyName;
                    return TextField(
                      controller: textCtrl, focusNode: focusNode, readOnly: selectedFamily != null,
                      decoration: InputDecoration(
                        labelText: selectedFamily != null ? 'Familia Seleccionada' : '1. Buscar familia por nombre',
                        filled: selectedFamily != null, fillColor: Colors.grey[200],
                        prefixIcon: const Icon(Icons.family_restroom),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: selectedFamily != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _vm.selectedFamily.value = null; textCtrl.clear(); }) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              const Text('Buscar y Añadir Alumnos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              TextField(
                controller: _alumnSearchCtrl,
                decoration: InputDecoration(labelText: '2. Buscar alumno por matrícula o nombre', prefixIcon: const Icon(Icons.person_search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onChanged: _vm.searchAlumns,
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<List<UserMiniModel>>(
                valueListenable: _vm.alumnResults,
                builder: (_, results, __) {
                  if (results.isEmpty) return const SizedBox.shrink();
                  return ConstrainedBox(constraints: const BoxConstraints(maxHeight: 200), child: Card(elevation: 2, child: ListView.builder(shrinkWrap: true, itemCount: results.length, itemBuilder: (_, i) {
                    final a = results[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.school)),
                      title: Text(a.fullName), subtitle: Text('Matrícula: ${a.matricula ?? 'N/A'}'),
                      trailing: IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () { _vm.addAlumn(a); _alumnSearchCtrl.clear(); FocusScope.of(context).unfocus(); }),
                    );
                  })));
                },
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<List<UserMiniModel>>(
                valueListenable: _vm.selectedAlumns,
                builder: (_, alumns, __) {
                  if (alumns.isEmpty) return const Center(child: Text('Ningún alumno añadido todavía.', style: TextStyle(color: Colors.grey)));
                  return Wrap(spacing: 8, runSpacing: 8, children: alumns.map((a) => Chip(label: Text(a.fullName), avatar: const Icon(Icons.school), onDeleted: () => _vm.removeAlumn(a))).toList());
                },
              ),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ValueListenableBuilder<bool>(
                valueListenable: _vm.loading,
                builder: (_, loading, __) => ElevatedButton.icon(
                  icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: Text(loading ? 'GUARDANDO...' : 'GUARDAR ASIGNACIONES'),
                  onPressed: loading ? null : () async {
                    final err = await _vm.saveAssignments();
                    if (!mounted) return;
                    if (err != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red)); return; }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_vm.selectedAlumns.value.length} alumno(s) asignado(s) con éxito.'), backgroundColor: Colors.green));
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

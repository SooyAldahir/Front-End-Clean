import 'package:flutter/material.dart';
import '../data/search_repository.dart';
import '../../chat/presentation/chat_page.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/models/search_result.dart';
import '../../../core/utils/url_helper.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchViewModel _vm = SearchViewModel();
  final _qCtrl = TextEditingController();

  @override
  void dispose() { _vm.dispose(); _qCtrl.dispose(); super.dispose(); }

  Future<void> _startChat(int id, String nombre) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo chat...'), duration: Duration(milliseconds: 800)));
    final idSala = await _vm.initPrivateChat(id);
    if (idSala != null && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(idSala: idSala, nombreChat: nombre)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, backgroundColor: AppColors.primary, title: const Text('Búsqueda general'), elevation: 0),
      body: ResponsiveContent(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
          child: Column(children: [
            _searchField(),
            const SizedBox(height: 8),
            Expanded(child: ValueListenableBuilder<bool>(
              valueListenable: _vm.loading,
              builder: (_, loading, __) {
                if (loading) return const Center(child: CircularProgressIndicator());
                if (!_vm.searched) return const Center(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Ingresa una matrícula, # de empleado o nombre de familia', textAlign: TextAlign.center),
                ));
                return ValueListenableBuilder<SearchResultModel>(
                  valueListenable: _vm.result,
                  builder: (_, result, __) => ListView(children: [
                    _section('Alumnos (${result.alumnos.length})',           'Sin alumnos',         result.alumnos.map(_userTile).toList()),
                    const SizedBox(height: 8),
                    _section('Empleados (${result.empleados.length})',        'Sin empleados',        result.empleados.map(_userTile).toList()),
                    const SizedBox(height: 8),
                    _section('Familias (${result.familias.length})',          'Sin familias',         result.familias.map(_familyTile).toList()),
                    const SizedBox(height: 8),
                    _section('Tutores Externos (${result.externos.length})',  'Sin tutores externos', result.externos.map(_userTile).toList()),
                  ]),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  Widget _searchField() => TextField(
    controller: _qCtrl, keyboardType: TextInputType.text, textInputAction: TextInputAction.search,
    onSubmitted: _vm.search,
    onChanged: (v) { if (v.trim().length >= 3) _vm.search(v); },
    decoration: InputDecoration(
      hintText: 'Ingrese matrícula, # de empleado o nombre de familia',
      filled: true, fillColor: Colors.white,
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppColors.accent)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppColors.accent)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: IconButton(icon: const Icon(Icons.search, color: AppColors.primary), onPressed: () => _vm.search(_qCtrl.text)),
    ),
  );

  Widget _section(String title, String emptyText, List<Widget> children) => Card(
    elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      if (children.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(emptyText, style: const TextStyle(color: Colors.black54)))
      else ...children,
    ])),
  );

  Widget _userTile(UserMiniModel u) {
    final tipo    = u.tipo.toUpperCase();
    final fotoUrl = toAbsoluteUrl(u.fotoPerfil);
    final doc     = (tipo == 'EMPLEADO' && u.numEmpleado != null)
        ? 'No. empleado: ${u.numEmpleado}'
        : (u.matricula != null ? 'Matrícula: ${u.matricula}' : '');
    return ListTile(
      leading: CircleAvatar(backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null, child: fotoUrl.isNotEmpty ? null : const Icon(Icons.person)),
      title: Text(u.fullName.isEmpty ? '—' : u.fullName),
      subtitle: Text([tipo, doc].where((e) => e.isNotEmpty).join(' · ')),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(tooltip: 'Enviar mensaje', icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue), onPressed: () => _startChat(u.id, u.fullName)),
        IconButton(tooltip: 'Ver detalle',    icon: const Icon(Icons.remove_red_eye_outlined),                onPressed: () => Navigator.pushNamed(context, AppRoutes.studentDetail, arguments: u.id)),
      ]),
    );
  }

  Widget _familyTile(FamilyMiniModel f) {
    final res   = f.residencia ?? 'Desconocida';
    final color = res.toLowerCase().startsWith('intern') ? Colors.green : Colors.red;
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.home)),
      title: Text(f.nombre.isEmpty ? '—' : f.nombre),
      subtitle: Text('Residencia: $res'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(tooltip: 'Ver detalle', icon: const Icon(Icons.remove_red_eye_outlined), onPressed: () => Navigator.pushNamed(context, AppRoutes.familyDetail, arguments: f.id)),
        Icon(Icons.chevron_right, color: color),
      ]),
      onTap: () => Navigator.pushNamed(context, AppRoutes.familyDetail, arguments: f.id),
    );
  }
}

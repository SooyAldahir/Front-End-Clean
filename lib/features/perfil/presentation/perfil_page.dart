import 'package:flutter/material.dart';
import 'perfil_viewmodel.dart';
import 'perfil_widgets.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/storage/token_storage.dart';

Color hexToColor(String hex, {Color def = Colors.blue}) {
  try {
    final buf = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buf.write('ff');
    buf.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buf.toString(), radix: 16));
  } catch (_) { return def; }
}

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final PerfilViewModel _vm = PerfilViewModel();

  @override
  void initState() { super.initState(); _vm.loadProfile(); }
  @override
  void dispose() { _vm.dispose(); super.dispose(); }

  String s(String k, [String d = '—']) {
    final v = _vm.data.value[k];
    if (v == null) return d;
    final t = v.toString().trim();
    return t.isEmpty ? d : t;
  }

  Color _statusColor(String st) {
    final l = st.toLowerCase();
    if (l.contains('inac') || l.contains('baja')) return Colors.red;
    if (l.contains('pend'))                       return Colors.orange;
    return Colors.green;
  }

  Future<void> _handleLogout() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Cerrar Sesión'), content: const Text('¿Seguro que deseas cerrar tu sesión?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true),  style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Cerrar Sesión')),
      ],
    ));
    if (ok != true || !mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    await TokenStorage().clear();
    await SessionStorage().clear();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Future<void> _showEstadoSelector() async {
    if (!_vm.isAlumno || _vm.userId == null) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final catalogo = await _vm.getCatalogoEstados();
    if (!mounted) return;
    Navigator.pop(context);
    if (catalogo.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudieron cargar los estados'))); return; }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('Actualizar mi estado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Expanded(child: ListView.builder(itemCount: catalogo.length, itemBuilder: (_, i) {
          final item = catalogo[i];
          return ListTile(
            leading: Icon(Icons.circle, size: 16, color: hexToColor(item['color'] ?? '#000000')),
            title: Text(item['descripcion']),
            onTap: () async {
              Navigator.pop(context);
              final err = await _vm.updateEstado(item['id_cat_estado'] as int);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Estado actualizado correctamente'), backgroundColor: err != null ? Colors.red : Colors.green));
            },
          );
        })),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fa),
      body: RefreshIndicator(
        onRefresh: _vm.loadProfile,
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (_, __) => [SliverAppBar(
            title: const Text('Mi perfil'), backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false, elevation: 0, floating: true, snap: true,
            actions: [IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: _handleLogout)],
          )],
          body: ValueListenableBuilder<bool>(
            valueListenable: _vm.loading,
            builder: (_, loading, __) {
              if (loading) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
              return ValueListenableBuilder<Map<String, dynamic>>(
                valueListenable: _vm.data,
                builder: (_, __, ___) => Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), physics: const AlwaysScrollableScrollPhysics(), children: [
                    HeaderCard(
                      name: s('name'), family: s('family'), residence: s('residence'),
                      status: s('status', 'Activo'), avatarUrl: s('avatarUrl'), primary: AppColors.primary,
                      statusColor: _vm.data.value['statusColorHex'] != null ? hexToColor(_vm.data.value['statusColorHex'].toString()) : _statusColor(s('status', 'Activo')),
                      onEditAvatar: () async {
                        final err = await _vm.pickAndUploadPhoto(context);
                        if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      },
                      onTapStatus: _vm.isAlumno ? _showEstadoSelector : null,
                    ),
                    const SizedBox(height: 12),
                    SectionCard(title: 'Datos', primary: AppColors.primary, children: [
                      InfoRow(icon: Icons.badge_outlined, label: s('docLabel'), value: s('docValue')),
                      InfoRow(icon: Icons.school_outlined, label: 'Programa',  value: s('grade')),
                      InfoRow(icon: Icons.cake_outlined,  label: 'Cumpleaños', value: s('birthday')),
                    ]),
                    const SizedBox(height: 12),
                    SectionCard(title: 'Contacto', primary: AppColors.primary, children: [
                      InfoRow(icon: Icons.call_outlined, label: 'Teléfono', value: s('phone')),
                      InfoRow(icon: Icons.mail_outline,  label: 'Correo',   value: s('email')),
                      if (!s('residence').toLowerCase().startsWith('intern')) InfoRow(icon: Icons.home_outlined, label: 'Dirección', value: s('address')),
                    ]),
                  ]),
                )),
              );
            },
          ),
        ),
      ),
    );
  }
}

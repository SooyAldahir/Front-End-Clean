import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../news/presentation/news_page.dart';
import '../../family/presentation/family_page.dart';
import '../../search/presentation/search_page.dart';
import '../../perfil/presentation/perfil_page.dart';
import '../../admin/presentation/admin_page.dart';
import '../../agenda/presentation/agenda_page.dart';
import '../../chat/presentation/my_chats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int    _selectedIndex = 0;
  String _userRole      = '';
  List<Map<String, dynamic>> _menu = [];

  @override
  void initState() {
    super.initState();
    _loadRole();
    SchedulerBinding.instance.addPostFrameCallback((_) => _checkEncuesta());
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('user');
    if (raw != null) {
      final user = jsonDecode(raw) as Map<String, dynamic>;
      final rol  = (user['nombre_rol'] ?? user['rol'] ?? '').toString();
      if (mounted) setState(() { _userRole = rol; _menu = _buildMenu(rol); });
    }
  }

  List<Map<String, dynamic>> _buildMenu(String rol) {
    final all = [
      {'ruta': 'news',   'icon': Icons.newspaper,           'label': 'Noticias'},
      {'ruta': 'chat',   'icon': Icons.chat_bubble,          'label': 'Mensajes'},
      {'ruta': 'family', 'icon': Icons.family_restroom,      'label': 'Familia'},
      {'ruta': 'search', 'icon': Icons.person_search,        'label': 'Buscar'},
      {'ruta': 'agenda', 'icon': Icons.calendar_month,       'label': 'Agenda'},
      {'ruta': 'admin',  'icon': Icons.admin_panel_settings, 'label': 'Admin'},
      {'ruta': 'perfil', 'icon': Icons.person,               'label': 'Perfil'},
    ];
    if (rol == 'Admin') return all;
    const familia = ['Padre','Madre','Tutor','PapaEDI','MamaEDI','Hijo','HijoEDI','Alumno','Estudiante','HijoSanguineo'];
    if (familia.contains(rol)) return all.where((o) => ['news','chat','family','perfil'].contains(o['ruta'])).toList();
    return [];
  }

  Widget _pageFor(String route) {
    switch (route) {
      case 'news':   return const NewsPage();
      case 'chat':   return const MyChatsPage();
      case 'family': return const FamiliyPage();
      case 'search': return const SearchPage();
      case 'agenda': return const AgendaPage();
      case 'admin':  return const AdminPage();
      case 'perfil': return const PerfilPage();
      default:       return const Center(child: Text('Página no encontrada'));
    }
  }

  Future<void> _checkEncuesta() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('encuesta_mostrada') ?? false) return;
    int count = (prefs.getInt('app_open_count') ?? 0) + 1;
    await prefs.setInt('app_open_count', count);
    if (count >= 6000 && mounted) _mostrarEncuesta();
  }

  void _mostrarEncuesta() => showDialog(
    context: context, barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [Icon(Icons.assignment, color: AppColors.primary), SizedBox(width: 10), Flexible(child: Text('¡Tu opinión nos importa!', style: TextStyle(fontSize: 18)))]),
      content: const Text('Ayúdanos a mejorar respondiendo esta breve encuesta.'),
      actions: [
        TextButton(onPressed: () async { final p = await SharedPreferences.getInstance(); await p.setInt('app_open_count', 0); if (mounted) Navigator.pop(context); }, child: const Text('Más tarde', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          onPressed: () async {
            final p = await SharedPreferences.getInstance(); await p.setBool('encuesta_mostrada', true);
            if (mounted) Navigator.pop(context);
            await launchUrl(Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSfmPuyryfjKzi372NfoNHPHrwyduHVrILEfvNG8g9JLEVxS5w/viewform'), mode: LaunchMode.externalApplication);
          },
          child: const Text('Responder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_menu.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_selectedIndex >= _menu.length) _selectedIndex = 0;
    final page = _pageFor(_menu[_selectedIndex]['ruta'] as String);

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 640) {
        return Scaffold(
          body: SafeArea(child: page),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.primary,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            items: _menu.map((o) => BottomNavigationBarItem(icon: Icon(o['icon'] as IconData), label: o['label'] as String)).toList(),
          ),
        );
      }
      return Scaffold(body: Row(children: [
        NavigationRail(
          backgroundColor: AppColors.primary,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          labelType: NavigationRailLabelType.all,
          selectedLabelTextStyle: const TextStyle(color: AppColors.accent),
          unselectedLabelTextStyle: const TextStyle(color: Colors.white),
          selectedIconTheme: const IconThemeData(color: AppColors.accent),
          unselectedIconTheme: const IconThemeData(color: Colors.white),
          destinations: _menu.map((o) => NavigationRailDestination(icon: Icon(o['icon'] as IconData), label: Text(o['label'] as String))).toList(),
        ),
        Expanded(child: page),
      ]));
    });
  }
}

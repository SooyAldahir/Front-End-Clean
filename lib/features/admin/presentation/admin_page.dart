import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, backgroundColor: AppColors.primary, elevation: 0),
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(children: [
            const SizedBox(height: 15),
            ...[
              _MenuItem(label: 'Agregar Familia',      icon: Icons.add_home,             route: AppRoutes.addFamily),
              _MenuItem(label: 'Asignar Alumnos',      icon: Icons.person_add,            route: AppRoutes.addAlumns),
              _MenuItem(label: 'Agregar Tutor Externo',icon: Icons.person_add_alt_1,      route: AppRoutes.addTutor),
              _MenuItem(label: 'Consultar Familias',   icon: Icons.visibility,            route: AppRoutes.getFamily),
              _MenuItem(label: 'Mi Agenda',            icon: Icons.calendar_month,        route: AppRoutes.agenda),
              _MenuItem(label: 'Reportes PDF',         icon: Icons.picture_as_pdf,        route: AppRoutes.reportes),
              _MenuItem(label: 'Cumpleaños',           icon: Icons.cake,                  route: AppRoutes.cumpleanos),
            ].map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: SizedBox(width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  onPressed: () => Navigator.pushNamed(context, item.route),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Icon(item.icon, color: Colors.white, size: 30),
                  ]),
                ),
              ),
            )),
          ]),
        ),
      ),
    );
  }
}

class _MenuItem { final String label, route; final IconData icon; const _MenuItem({required this.label, required this.icon, required this.route}); }

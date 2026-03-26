class AppRoles {
  AppRoles._();

  static const admin          = 'Admin';
  static const papaEDI        = 'PapaEDI';
  static const mamaEDI        = 'MamaEDI';
  static const hijoEDI        = 'HijoEDI';
  static const hijoSanguineo  = 'HijoSanguineo';
  static const padre          = 'Padre';
  static const madre          = 'Madre';
  static const tutor          = 'Tutor';

  static const List<String> padres   = [papaEDI, mamaEDI, padre, madre, tutor];
  static const List<String> hijos    = [hijoEDI, hijoSanguineo];
  static const List<String> autoridad = [admin, papaEDI, mamaEDI, padre, madre, tutor];
  static const List<String> todos    = [admin, ...padres, ...hijos];

  static bool esPadre(String rol)     => padres.contains(rol);
  static bool esHijo(String rol)      => hijos.contains(rol) || rol.toUpperCase() == 'ALUMNO';
  static bool esAdmin(String rol)     => rol == admin;
  static bool esAutoridad(String rol) => autoridad.any((r) => rol.contains(r));
}

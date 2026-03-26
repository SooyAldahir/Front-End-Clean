class UserMiniModel {
  final int id;
  final String nombre;
  final String apellido;
  final String tipo;
  final int? matricula;
  final int? numEmpleado;
  final String? email;
  final String? fotoPerfil;

  const UserMiniModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.tipo,
    this.matricula,
    this.numEmpleado,
    this.email,
    this.fotoPerfil,
  });

  String get fullName => '$nombre $apellido'.trim();

  factory UserMiniModel.fromJson(Map<String, dynamic> j) => UserMiniModel(
        id:          (j['IdUsuario'] ?? j['id'] ?? j['id_usuario'] ?? 0) as int,
        nombre:      (j['Nombre']    ?? j['nombre']    ?? '').toString(),
        apellido:    (j['Apellido']  ?? j['apellido']  ?? '').toString(),
        tipo:        (j['TipoUsuario'] ?? j['tipo_usuario'] ?? '').toString(),
        matricula:   _toInt(j['Matricula']   ?? j['matricula']),
        numEmpleado: _toInt(j['NumEmpleado'] ?? j['num_empleado']),
        email:       (j['E_mail'] ?? j['correo'])?.toString(),
        fotoPerfil:  (j['FotoPerfil'] ?? j['foto_perfil'])?.toString(),
      );
}

class FamilyMiniModel {
  final int id;
  final String nombre;
  final String? residencia;

  const FamilyMiniModel({required this.id, required this.nombre, this.residencia});

  factory FamilyMiniModel.fromJson(Map<String, dynamic> j) => FamilyMiniModel(
        id:         (j['FamiliaID'] ?? j['id_familia'] ?? j['id'] ?? 0) as int,
        nombre:     (j['Nombre_Familia'] ?? j['nombre_familia'] ?? j['nombre'] ?? '').toString(),
        residencia: (j['Residencia'] ?? j['residencia'])?.toString(),
      );
}

class SearchResultModel {
  final List<UserMiniModel> alumnos;
  final List<UserMiniModel> empleados;
  final List<FamilyMiniModel> familias;
  final List<UserMiniModel> externos;

  const SearchResultModel({
    this.alumnos   = const [],
    this.empleados = const [],
    this.familias  = const [],
    this.externos  = const [],
  });
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

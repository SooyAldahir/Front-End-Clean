class UserModel {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final String tipoUsuario;
  final int idRol;
  final String nombreRol;
  final String sessionToken;
  final int? matricula;
  final int? numEmpleado;
  final String? fotoPerfil;
  final String? estado;
  final bool activo;
  final int? idFamilia;
  final String? nombreFamilia;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.tipoUsuario,
    required this.idRol,
    required this.nombreRol,
    required this.sessionToken,
    this.matricula,
    this.numEmpleado,
    this.fotoPerfil,
    this.estado,
    this.activo = true,
    this.idFamilia,
    this.nombreFamilia,
  });

  String get fullName => '$nombre $apellido'.trim();

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id:            j['id_usuario'] ?? j['IdUsuario'] ?? j['id'] ?? 0,
        nombre:        (j['nombre']    ?? j['Nombre']    ?? '').toString(),
        apellido:      (j['apellido']  ?? j['Apellido']  ?? '').toString(),
        correo:        (j['correo']    ?? j['E_mail']    ?? '').toString(),
        tipoUsuario:   (j['tipo_usuario'] ?? j['TipoUsuario'] ?? '').toString(),
        idRol:         j['id_rol'] ?? 0,
        nombreRol:     (j['nombre_rol'] ?? j['rol'] ?? '').toString(),
        sessionToken:  (j['session_token'] ?? j['token'] ?? '').toString(),
        matricula:     j['matricula']    is int ? j['matricula']    : int.tryParse(j['matricula']?.toString()    ?? ''),
        numEmpleado:   j['num_empleado'] is int ? j['num_empleado'] : int.tryParse(j['num_empleado']?.toString() ?? ''),
        fotoPerfil:    j['foto_perfil']?.toString(),
        estado:        j['estado']?.toString(),
        activo:        j['activo'] == true || j['activo'] == 1,
        idFamilia:     j['id_familia'] is int ? j['id_familia'] : int.tryParse(j['id_familia']?.toString() ?? ''),
        nombreFamilia: j['nombre_familia']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id_usuario':   id,
        'nombre':       nombre,
        'apellido':     apellido,
        'correo':       correo,
        'tipo_usuario': tipoUsuario,
        'id_rol':       idRol,
        'nombre_rol':   nombreRol,
        'session_token':sessionToken,
        'matricula':    matricula,
        'num_empleado': numEmpleado,
        'foto_perfil':  fotoPerfil,
        'estado':       estado,
        'activo':       activo,
        'id_familia':   idFamilia,
        'nombre_familia': nombreFamilia,
      };
}

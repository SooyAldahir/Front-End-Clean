class FamilyMemberModel {
  final int idMiembro;
  final int idUsuario;
  final String fullName;
  final String tipoMiembro;
  final int? matricula;
  final String? telefono;
  final String? carrera;
  final String? fechaNacimiento;
  final String? fotoPerfil;

  const FamilyMemberModel({
    required this.idMiembro,
    required this.idUsuario,
    required this.fullName,
    required this.tipoMiembro,
    this.matricula,
    this.telefono,
    this.carrera,
    this.fechaNacimiento,
    this.fotoPerfil,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> j) {
    String? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        final date = DateTime.parse(d.toString());
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (_) {
        return d.toString();
      }
    }

    final nombre   = (j['nombre']   ?? '').toString();
    final apellido = (j['apellido'] ?? '').toString();

    return FamilyMemberModel(
      idMiembro:       (j['id_miembro']  ?? 0) as int,
      idUsuario:       (j['id_usuario']  ?? 0) as int,
      fullName:        '$nombre $apellido'.trim(),
      tipoMiembro:     (j['tipo_miembro'] ?? 'HIJO').toString(),
      matricula:       (j['matricula']   as num?)?.toInt(),
      telefono:        j['telefono']?.toString(),
      carrera:         j['carrera']?.toString(),
      fechaNacimiento: parseDate(j['fecha_nacimiento']),
      fotoPerfil:      j['foto_perfil_url']?.toString(),
    );
  }
}

class FamilyModel {
  final int? id;
  final String familyName;
  final String? fatherName;
  final String? motherName;
  final String? residencia;
  final String? direccion;
  final String? descripcion;
  final String? fotoPortadaUrl;
  final String? fotoPerfilUrl;
  final List<FamilyMemberModel> householdChildren;
  final List<FamilyMemberModel> assignedStudents;
  final int? fatherEmployeeId;
  final int? motherEmployeeId;
  final String? papaNumEmpleado;
  final String? mamaNumEmpleado;
  final String? papaTelefono;
  final String? mamaTelefono;
  final String? papaFotoPerfilUrl;
  final String? mamaFotoPerfilUrl;

  const FamilyModel({
    required this.id,
    required this.familyName,
    this.fatherName,
    this.motherName,
    this.residencia,
    this.direccion,
    this.descripcion,
    this.fotoPortadaUrl,
    this.fotoPerfilUrl,
    this.householdChildren = const [],
    this.assignedStudents  = const [],
    this.fatherEmployeeId,
    this.motherEmployeeId,
    this.papaNumEmpleado,
    this.mamaNumEmpleado,
    this.papaTelefono,
    this.mamaTelefono,
    this.papaFotoPerfilUrl,
    this.mamaFotoPerfilUrl,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> j) {
    String? normalizeRes(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim().toUpperCase();
      if (s.startsWith('INT')) return 'Interna';
      if (s.startsWith('EXT')) return 'Externa';
      return v.toString();
    }

    final household = <FamilyMemberModel>[];
    final assigned  = <FamilyMemberModel>[];

    if (j['miembros'] is List) {
      for (final m in j['miembros'] as List) {
        if (m is Map<String, dynamic>) {
          final member = FamilyMemberModel.fromJson(m);
          if (member.tipoMiembro == 'HIJO') {
            household.add(member);
          } else if (member.tipoMiembro == 'ALUMNO_ASIGNADO') {
            assigned.add(member);
          }
        }
      }
    }

    return FamilyModel(
      id:              (j['id_familia'] ?? j['FamiliaID'] ?? j['id']) as int?,
      familyName:      (j['nombre_familia'] ?? j['Nombre_Familia'] ?? j['nombre'] ?? '').toString(),
      fatherName:      (j['papa_nombre'] ?? j['Padre'] ?? j['fatherName'])?.toString(),
      motherName:      (j['mama_nombre'] ?? j['Madre'] ?? j['motherName'])?.toString(),
      residencia:      normalizeRes(j['residencia'] ?? j['Residencia']),
      direccion:       (j['direccion']   ?? j['Direccion'])?.toString(),
      descripcion:     (j['descripcion'] ?? j['Descripcion'])?.toString(),
      fotoPortadaUrl:  j['foto_portada_url']?.toString(),
      fotoPerfilUrl:   j['foto_perfil_url']?.toString(),
      householdChildren: household,
      assignedStudents:  assigned,
      fatherEmployeeId:  (j['papa_id'] ?? j['Papa_id'] ?? j['PapaId']) as int?,
      motherEmployeeId:  (j['mama_id'] ?? j['Mama_id'] ?? j['MamaId']) as int?,
      papaNumEmpleado:   j['papa_num_empleado']?.toString(),
      mamaNumEmpleado:   j['mama_num_empleado']?.toString(),
      papaTelefono:      j['papa_telefono']?.toString(),
      mamaTelefono:      j['mama_telefono']?.toString(),
      papaFotoPerfilUrl: j['papa_foto_perfil_url']?.toString(),
      mamaFotoPerfilUrl: j['mama_foto_perfil_url']?.toString(),
    );
  }

  /// Alias for residencia — backwards compatibility
  String get residence => residencia ?? '';

  FamilyModel copyWith({
    int? id, String? familyName, String? fatherName, String? motherName,
    String? residencia, String? direccion, String? descripcion,
    String? fotoPortadaUrl, String? fotoPerfilUrl,
    List<FamilyMemberModel>? householdChildren,
    List<FamilyMemberModel>? assignedStudents,
    int? fatherEmployeeId, int? motherEmployeeId,
  }) => FamilyModel(
    id:                id              ?? this.id,
    familyName:        familyName      ?? this.familyName,
    fatherName:        fatherName      ?? this.fatherName,
    motherName:        motherName      ?? this.motherName,
    residencia:        residencia      ?? this.residencia,
    direccion:         direccion       ?? this.direccion,
    descripcion:       descripcion     ?? this.descripcion,
    fotoPortadaUrl:    fotoPortadaUrl  ?? this.fotoPortadaUrl,
    fotoPerfilUrl:     fotoPerfilUrl   ?? this.fotoPerfilUrl,
    householdChildren: householdChildren ?? this.householdChildren,
    assignedStudents:  assignedStudents  ?? this.assignedStudents,
    fatherEmployeeId:  fatherEmployeeId  ?? this.fatherEmployeeId,
    motherEmployeeId:  motherEmployeeId  ?? this.motherEmployeeId,
    papaNumEmpleado:   papaNumEmpleado   ?? this.papaNumEmpleado,
    mamaNumEmpleado:   mamaNumEmpleado   ?? this.mamaNumEmpleado,
  );
}

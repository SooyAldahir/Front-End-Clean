/// Centraliza todos los endpoints de la API.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login           = '/api/auth/login';
  static const String logout          = '/api/auth/logout';
  static const String resetPassword   = '/api/auth/reset-password';

  // Usuarios
  static const String usuarios        = '/api/usuarios';
  static String usuarioById(int id)   => '/api/usuarios/$id';
  static const String updateToken     = '/api/usuarios/update-token';
  static const String cumpleanos      = '/api/usuarios/cumpleanos';
  static const String familiasByDoc   = '/api/usuarios/familias/by-doc/search';

  // Familias
  static const String familias            = '/api/familias';
  static String familiaById(int id)       => '/api/familias/$id';
  static const String familiasSearch      = '/api/familias/search';
  static const String familiasAvailable   = '/api/familias/available';
  static const String familiasReporte     = '/api/familias/reporte-completo';
  static String familiaFotos(int id)      => '/api/familias/$id/fotos';
  static String familiaDescripcion(int id)=> '/api/familias/$id/descripcion';
  static String familiaPorIdent(int id)   => '/api/familias/por-ident/$id';

  // Miembros
  static const String miembros        = '/api/miembros';
  static const String miembrosBulk    = '/api/miembros/bulk';
  static String miembroById(int id)   => '/api/miembros/$id';
  static String miembrosByFamilia(int id) => '/api/miembros/familia/$id';

  // Publicaciones
  static const String publicaciones           = '/api/publicaciones';
  static const String feedGlobal              = '/api/publicaciones/feed/global';
  static const String misPosts                = '/api/publicaciones/mis-posts';
  static const String institucional           = '/api/publicaciones/institucional';
  static String postsByFamilia(int id)        => '/api/publicaciones/familia/$id';
  static String postsPendientes(int id)       => '/api/publicaciones/familia/$id/pendientes';
  static String postEstado(int id)            => '/api/publicaciones/$id/estado';
  static String postLike(int id)              => '/api/publicaciones/$id/like';
  static String postComentarios(int id)       => '/api/publicaciones/$id/comentarios';
  static String comentarioById(int id)        => '/api/publicaciones/comentarios/$id';
  static String postById(int id)              => '/api/publicaciones/$id';

  // Agenda
  static const String agenda          = '/api/agenda';
  static String agendaById(int id)    => '/api/agenda/$id';

  // Mensajes familiares
  static const String mensajes                = '/api/mensajes';
  static String mensajesByFamilia(int id)     => '/api/mensajes/familia/$id';

  // Chat
  static const String chatPrivado     = '/api/chat/private';
  static const String chatGrupo       = '/api/chat/group';
  static const String chatMensaje     = '/api/chat/message';
  static const String misChats        = '/api/chat';
  static String chatMensajes(int id)  => '/api/chat/$id/messages';

  // Estados
  static const String estadosCatalogo     = '/api/estados/catalogo';
  static const String estados             = '/api/estados';
  static String estadosByUsuario(int id)  => '/api/estados/usuario/$id';
  static String estadoCerrar(int id)      => '/api/estados/$id/cerrar';

  // Provisiones
  static const String provisiones                 = '/api/provisiones';
  static String provisionesByFamilia(int id)       => '/api/provisiones/familia/$id';
  static const String detalleProvision             = '/api/detalle-provision';
  static String detalleByProvision(int id)         => '/api/detalle-provision/provision/$id';

  // Fotos
  static const String fotos                   = '/api/fotos';
  static String fotosByPost(int id)           => '/api/fotos/post/$id';
  static String fotosByFamilia(int id)        => '/api/fotos/familia/$id';

  // Solicitudes
  static const String solicitudes                 = '/api/solicitudes';
  static String solicitudesByFamilia(int id)       => '/api/solicitudes/familia/$id';
  static String solicitudEstado(int id)            => '/api/solicitudes/$id/estado';

  // Search
  static const String search          = '/api/search';

  // Roles
  static const String roles           = '/api/roles';
}

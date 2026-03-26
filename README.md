# EDI 301 — Frontend Flutter

<div align="center">

```
 ███████╗██████╗ ██╗    ██████╗  ██████╗  ██╗
 ██╔════╝██╔══██╗██║    ╚════██╗██╔═████╗███║
 █████╗  ██║  ██║██║     █████╔╝██║██╔██║╚██║
 ██╔══╝  ██║  ██║██║     ╚═══██╗████╔╝██║ ██║
 ███████╗██████╔╝██║    ██████╔╝╚██████╔╝ ██║
 ╚══════╝╚═════╝ ╚═╝    ╚═════╝  ╚═════╝  ╚═╝
```

**Aplicación móvil de gestión de familias escolares**  
Flutter · Clean Architecture · Node.js API

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Messaging-FFCA28?style=flat-square&logo=firebase)

</div>

---

## Índice

- [Descripción](#descripción)
- [Arquitectura](#arquitectura)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Módulos y Funcionalidades](#módulos-y-funcionalidades)
- [Patrones Implementados](#patrones-implementados)
- [Modelos de Datos](#modelos-de-datos)
- [Navegación y Rutas](#navegación-y-rutas)
- [Variables de Entorno](#variables-de-entorno)

---

## Descripción

EDI 301 es una aplicación móvil desarrollada en **Flutter** para la gestión integral de familias del sistema escolar EDI. Permite a alumnos, padres, empleados y administradores mantenerse conectados a través de noticias, chat familiar, agenda de eventos, directorio y más.

---

## Arquitectura

El proyecto implementa **Arquitectura Limpia (Clean Architecture)** con separación estricta en capas:

```
┌─────────────────────────────────────────────────────┐
│                   PRESENTATION                       │
│         Pages  ←→  ViewModels  ←→  Widgets           │
├─────────────────────────────────────────────────────┤
│                      DATA                            │
│              Repositories  ←→  ApiClient             │
├─────────────────────────────────────────────────────┤
│                     SHARED                           │
│          Models  |  Constants  |  Widgets            │
├─────────────────────────────────────────────────────┤
│                      CORE                            │
│     Network  |  Storage  |  Socket  |  Utils         │
└─────────────────────────────────────────────────────┘
```

**Patrón de estado:** `ValueNotifier` + `ValueListenableBuilder` (sin dependencias externas de estado management).

---

## Estructura del Proyecto

```
lib/
├── main.dart                          # Entry point, Firebase init, rutas
│
├── core/                              # Infraestructura compartida
│   ├── network/
│   │   ├── api_client.dart            # HTTP client singleton (baseUrl, headers, multipart)
│   │   └── api_endpoints.dart         # Todos los endpoints de la API centralizados
│   ├── storage/
│   │   ├── token_storage.dart         # FlutterSecureStorage (JWT)
│   │   └── session_storage.dart       # SharedPreferences (datos de sesión)
│   ├── socket/
│   │   └── socket_service.dart        # Socket.io singleton (rooms, eventos)
│   └── utils/
│       ├── url_helper.dart            # Conversión URL relativa → absoluta
│       └── otp_service.dart           # Generación y validación de OTP
│
├── shared/                            # Código compartido entre features
│   ├── constants/
│   │   ├── app_colors.dart            # Paleta de colores del sistema
│   │   ├── app_roles.dart             # Roles de usuario y grupos de roles
│   │   └── app_routes.dart            # Nombres de rutas nombradas
│   ├── models/
│   │   ├── user.dart                  # UserModel (empleado/alumno)
│   │   ├── family.dart                # FamilyModel + FamilyMemberModel + getter residence
│   │   └── search_result.dart         # SearchResultModel, UserMiniModel, FamilyMiniModel
│   └── widgets/
│       └── app_widgets.dart           # ResponsiveContent, NetworkImageWithFallback,
│                                      # AvatarWidget, AppButton
│
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   └── presentation/
│   │       ├── auth_viewmodels.dart   # LoginViewModel, RegisterViewModel, ForgotPasswordViewModel
│   │       ├── login_page.dart
│   │       ├── register_page.dart
│   │       └── forgot_password_page.dart
│   │
│   ├── home/
│   │   └── presentation/home_page.dart  # Navegación adaptativa (BottomNav / NavigationRail)
│   │
│   ├── family/
│   │   ├── data/family_repository.dart
│   │   └── presentation/
│   │       ├── family_viewmodel.dart     # FamilyViewModel, EditFamilyViewModel
│   │       ├── family_page.dart          # Vista principal con fotos, miembros, galería
│   │       ├── family_controller_legacy.dart
│   │       ├── edit_controller.dart
│   │       └── edit_page.dart
│   │
│   ├── news/
│   │   ├── data/news_repository.dart
│   │   └── presentation/
│   │       ├── news_viewmodel.dart        # NewsViewModel, CreatePostViewModel, NotificationsViewModel
│   │       ├── news_page.dart             # Feed con likes, comentarios, animación de corazón
│   │       ├── create_post_page.dart
│   │       └── (notifications_page → features/notifications/)
│   │
│   ├── chat/
│   │   ├── data/chat_repository.dart
│   │   └── presentation/
│   │       ├── chat_viewmodel.dart        # MyChatsViewModel, ChatViewModel, ChatFamilyViewModel
│   │       ├── my_chats_page.dart
│   │       ├── chat_page.dart
│   │       └── chat_family_page.dart
│   │
│   ├── agenda/
│   │   ├── data/agenda_repository.dart    # EventoModel
│   │   └── presentation/
│   │       ├── agenda_viewmodel.dart      # AgendaViewModel, CreateEventViewModel
│   │       ├── agenda_page.dart
│   │       ├── agenda_detail_page.dart
│   │       └── crear_evento_page.dart
│   │
│   ├── admin/
│   │   ├── data/
│   │   │   ├── admin_repository.dart      # Familias, miembros, usuarios, FCM token
│   │   │   └── reporte_service.dart       # Generación de PDFs de reportes
│   │   └── presentation/
│   │       ├── admin_viewmodels.dart      # AddFamilyViewModel, AddAlumnsViewModel,
│   │       │                              # AddTutorViewModel, GetFamilyViewModel
│   │       ├── admin_page.dart
│   │       ├── add_family_page.dart
│   │       ├── add_alumns_page.dart
│   │       ├── add_tutor_page.dart
│   │       ├── get_family_page.dart
│   │       ├── get_family_controller.dart
│   │       ├── family_detail_page.dart
│   │       ├── student_detail_page.dart
│   │       ├── birthday_page.dart
│   │       └── reportes_page.dart
│   │
│   ├── perfil/
│   │   ├── data/perfil_repository.dart
│   │   └── presentation/
│   │       ├── perfil_viewmodel.dart      # PerfilViewModel (carga local + servidor)
│   │       ├── perfil_page.dart
│   │       └── perfil_widgets.dart        # HeaderCard, SectionCard, InfoRow
│   │
│   ├── search/
│   │   ├── data/search_repository.dart    # Incluye SearchViewModel
│   │   └── presentation/
│   │       ├── search_page.dart
│   │       └── family_mapper.dart
│   │
│   └── notifications/
│       └── presentation/notifications_page.dart
│
├── src/widgets/
│   └── family_gallery.dart            # Galería de fotos de familia (grid + visor fullscreen)
│
└── tools/
    ├── media_picker.dart              # Selector de imagen (cámara / galería)
    ├── notification_service.dart      # Notificaciones locales (flutter_local_notifications)
    ├── generic_reminders.dart         # Recordatorios del sistema
    └── fullscreen_image_viewer.dart   # Visor de imagen a pantalla completa con Hero
```

---

## Requisitos

| Herramienta | Versión mínima |
|---|---|
| Flutter SDK | 3.10+ |
| Dart | 3.0+ |
| Android SDK | API 21 (Android 5.0) |
| iOS | 12.0+ |
| Xcode | 14+ (para iOS) |

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/SooyAldahir/Front-End-Clean.git
cd Front-End-Clean

# 2. Instalar dependencias
flutter pub get

# 3. Verificar entorno
flutter doctor

# 4. Ejecutar en dispositivo/emulador
flutter run
```

---

## Configuración

### URL del Backend

Edita `lib/core/network/api_client.dart`:

```dart
class ApiClient {
  // Desarrollo local (misma red WiFi que el dispositivo)
  static const String baseUrl = 'http://192.168.X.X:3000';

  // Producción
  // static const String baseUrl = 'https://edi301.apps.isdapps.uk';
}
```

> **Importante:** El celular y la Mac deben estar en la misma red WiFi.  
> Obtén tu IP con: `ipconfig getifaddr en0`

### Firebase

1. Descarga `google-services.json` desde Firebase Console
2. Colócalo en `android/app/google-services.json`
3. Para iOS, coloca `GoogleService-Info.plist` en `ios/Runner/`

> ⚠️ **Nunca** subas estos archivos a Git — ya están en `.gitignore`

### Android Signing (release)

Crea `android/key.properties`:

```properties
storePassword=tu_password
keyPassword=tu_password
keyAlias=tu_alias
storeFile=../tu_keystore.jks
```

---

## Módulos y Funcionalidades

### Autenticación
- Login con correo institucional y contraseña
- Registro en 4 pasos: búsqueda por matrícula/empleado, verificación de email con OTP, creación de contraseña
- Recuperación de contraseña con OTP

### Home
- Navegación adaptativa: `BottomNavigationBar` en móvil, `NavigationRail` en tablet/desktop
- Menú dinámico según rol del usuario
- Encuesta de satisfacción con conteo de aperturas

### Familia
- Vista de familia con foto de perfil, portada, descripción
- Listado de padres e hijos con fotos, teléfono, carrera
- Galería de fotos familiar con visor fullscreen
- Edición de fotos de perfil y portada (Cloudinary)
- Chat familiar integrado

### Noticias (Feed)
- Feed paginado con carga incremental
- Posts con imagen, likes con animación de corazón, comentarios
- Crear publicaciones (texto + foto)
- Flujo de aprobación para roles no-admin
- Actualización en tiempo real via Socket.io

### Chat
- Chat privado entre usuarios
- Chat grupal de familia
- Polling + Socket.io para mensajes en tiempo real
- Colores de burbuja por nombre de usuario

### Agenda
- Listado de eventos próximos
- Crear/editar/eliminar eventos con imagen, fecha, hora
- Recordatorios del sistema
- Feed integrado con eventos próximos

### Admin
- Crear familias (buscar papá/mamá por no. empleado, asignar hijos)
- Asignar alumnos a familias existentes
- Registrar tutores externos
- Consultar directorio de familias
- Ver detalle completo de familia y alumno
- Reportes PDF de familias
- Cumpleaños del día

### Búsqueda Global
- Búsqueda por nombre, matrícula o no. de empleado
- Resultados separados: Alumnos, Empleados, Familias, Externos
- Acción directa: iniciar chat o ver detalle

### Perfil
- Ver datos del usuario (datos académicos, contacto, dirección)
- Actualizar foto de perfil
- Actualizar estado (alumnos)
- Cerrar sesión

---

## Patrones Implementados

### ValueNotifier + ValueListenableBuilder

Patrón de estado reactivo sin dependencias externas:

```dart
// ViewModel
class NewsViewModel {
  final posts   = ValueNotifier<List<dynamic>>([]);
  final loading = ValueNotifier<bool>(true);

  Future<void> loadFeed() async {
    loading.value = true;
    posts.value = await _repo.getGlobalFeed();
    loading.value = false;
  }
}

// Page
ValueListenableBuilder<bool>(
  valueListenable: _vm.loading,
  builder: (_, loading, __) => loading
    ? CircularProgressIndicator()
    : PostList(posts: _vm.posts.value),
)
```

### Repository Pattern

Cada feature tiene su propio repositorio que encapsula las llamadas HTTP:

```dart
class NewsRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getGlobalFeed({int page = 1}) async {
    final res = await _api.getJson(ApiEndpoints.feedGlobal, query: {'page': page});
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {'data': [], 'hasMore': false};
  }
}
```

### Socket.io Singleton

```dart
// Unirse a rooms según contexto
_socket.joinUserRoom(userId);
_socket.joinFamilyRoom(familiaId);
_socket.joinInstitucionalRoom();

// Escuchar eventos
_socket.on('feed_actualizado', (_) => loadFeed());
```

---

## Modelos de Datos

### FamilyModel

```dart
class FamilyModel {
  final int?   id;
  final String familyName;
  final String? residencia;
  final String? fotoPerfilUrl;
  final String? fotoPortadaUrl;
  final List<FamilyMemberModel> miembros;

  // Getter de compatibilidad
  String get residence => residencia ?? '';
}
```

### UserMiniModel (búsquedas)

```dart
class UserMiniModel {
  final int    id;
  final String nombre, apellido;
  final String tipo;          // ALUMNO | EMPLEADO | EXTERNO
  final String? matricula, numEmpleado, email, fotoPerfil;

  String get fullName => '$nombre $apellido'.trim();
}
```

---

## Navegación y Rutas

Todas las rutas están centralizadas en `AppRoutes`:

```dart
class AppRoutes {
  static const login          = 'login';
  static const register       = 'register';
  static const forgotPassword = 'forgot_password';
  static const home           = 'home';
  static const family         = 'family';
  static const news           = 'news';
  static const chat           = 'chat';
  static const search         = 'search';
  static const admin          = 'admin';
  static const perfil         = 'perfil';
  static const agenda         = 'agenda';
  // ... etc
}
```

Uso:
```dart
Navigator.pushNamed(context, AppRoutes.familyDetail, arguments: familyId);
```

---

## Variables de Entorno

No se usan archivos `.env` en Flutter. La configuración sensible se maneja así:

| Dato | Archivo | En Git |
|---|---|---|
| URL del backend | `api_client.dart` | ✅ (sin credenciales) |
| Firebase config Android | `google-services.json` | ❌ |
| Firebase config iOS | `GoogleService-Info.plist` | ❌ |
| Keystore Android | `key.properties` + `.jks` | ❌ |

---

<div align="center">

Desarrollado con ❤️ para Capellania Universitaria - Universidad Linda Vista SA. de CV.

</div>

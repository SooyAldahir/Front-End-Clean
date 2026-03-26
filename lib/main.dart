import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/socket/socket_service.dart';
import 'core/storage/session_storage.dart';
import 'features/admin/data/admin_repository.dart';
import 'tools/notification_service.dart';
import 'shared/constants/app_routes.dart';

// ─── Pages ────────────────────────────────────────────────────────────────────
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/auth/presentation/forgot_password_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/family/presentation/family_page.dart';
import 'features/family/presentation/edit_page.dart';
import 'features/news/presentation/news_page.dart';
import 'features/search/presentation/search_page.dart';
import 'features/admin/presentation/admin_page.dart';
import 'features/perfil/presentation/perfil_page.dart';
import 'features/admin/presentation/add_family_page.dart';
import 'features/admin/presentation/add_alumns_page.dart';
import 'features/admin/presentation/add_tutor_page.dart';
import 'features/admin/presentation/get_family_page.dart';
import 'features/admin/presentation/family_detail_page.dart';
import 'features/admin/presentation/student_detail_page.dart';
import 'features/agenda/presentation/agenda_page.dart';
import 'features/agenda/presentation/agenda_detail_page.dart';
import 'features/agenda/presentation/crear_evento_page.dart';
import 'features/admin/presentation/reportes_page.dart';
import 'features/notifications/presentation/notifications_page.dart';
import 'features/admin/presentation/birthday_page.dart';
import 'features/agenda/data/agenda_repository.dart';

// ─── Firebase background handler ─────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// ─── FCM sync ────────────────────────────────────────────────────────────────
Future<void> _syncFcmIfLoggedIn() async {
  final session  = SessionStorage();
  final userId   = await session.getUserId();
  if (userId == null) return;
  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null || fcmToken.isEmpty) return;
  final lastSent = await session.getLastFcmToken();
  if (lastSent == fcmToken) return;
  final ok = await AdminRepository().updateFcmToken(userId, fcmToken);
  if (ok) await session.saveLastFcmToken(fcmToken);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  SocketService().initSocket();

  final noti = NotificationService();
  await noti.init();
  await noti.requestPermissions();

  FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
    final n = msg.notification;
    if (n != null) noti.showNotification(id: n.hashCode, title: n.title ?? 'Sin título', body: n.body ?? '', payload: msg.data['tipo'] ?? 'GENERAL');
  });

  await _syncFcmIfLoggedIn();

  // Refresh token listener
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final session = SessionStorage();
    final userId  = await session.getUserId();
    if (userId == null) return;
    final lastSent = await session.getLastFcmToken();
    if (lastSent == newToken) return;
    final ok = await AdminRepository().updateFcmToken(userId, newToken);
    if (ok) await session.saveLastFcmToken(newToken);
  });

  final session      = SessionStorage();
  final isLoggedIn   = await session.getUser() != null;
  final initialRoute = isLoggedIn ? AppRoutes.home : AppRoutes.login;

  HttpOverrides.global = _MyHttpOverrides();
  runApp(MyApp(initialRoute: initialRoute));
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..badCertificateCallback = (_, __, ___) => true;
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EDI 301',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white), useMaterial3: false),
      initialRoute: initialRoute,
      routes: {
        AppRoutes.login:          (_) => const LoginPage(),
        AppRoutes.register:       (_) => const RegisterPage(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
        AppRoutes.home:           (_) => const HomePage(),
        AppRoutes.family:         (_) => const FamiliyPage(),
        AppRoutes.edit: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          return EditPage(familyId: args is int ? args : 0);
        },
        AppRoutes.news:           (_) => const NewsPage(),
        AppRoutes.search:         (_) => const SearchPage(),
        AppRoutes.admin:          (_) => const AdminPage(),
        AppRoutes.perfil:         (_) => const PerfilPage(),
        AppRoutes.addFamily:      (_) => const AddFamilyPage(),
        AppRoutes.addAlumns:      (_) => const AddAlumnsPage(),
        AppRoutes.addTutor:       (_) => const AddTutorPage(),
        AppRoutes.getFamily:      (_) => const GetFamilyPage(),
        AppRoutes.familyDetail:   (_) => const FamilyDetailPage(),
        AppRoutes.studentDetail:  (_) => const StudentDetailPage(),
        AppRoutes.agenda:         (_) => const AgendaPage(),
        AppRoutes.agendaDetail: (ctx) {
          final evento = ModalRoute.of(ctx)!.settings.arguments as EventoModel;
          return AgendaDetailPage(evento: evento);
        },
        AppRoutes.crearEvento: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          return CreateEventPage(eventoExistente: args is Map<String, dynamic> ? args : null);
        },
        AppRoutes.reportes:       (_) => const ReportesPage(),
        AppRoutes.notifications:  (_) => const NotificationsPage(),
        AppRoutes.cumpleanos:     (_) => const BirthdaysPage(),
      },
    );
  }
}

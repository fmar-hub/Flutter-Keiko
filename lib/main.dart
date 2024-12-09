import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';
import 'package:flutter_keiko/firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_keiko/theme/theme_provider.dart';
import 'package:provider/provider.dart';

// Importa las páginas de ambos proyectos
import 'package:flutter_keiko/pages/user_auth/login.dart';
import 'package:flutter_keiko/pages/home/home.dart';
import 'screens/admin_dashboard.dart';
import 'screens/user_management.dart';
import 'screens/role_management.dart';
import 'screens/system_logs.dart';
import 'screens/habitspage.dart';
import 'package:flutter_keiko/services/firebase_habit_service.dart';

// Define la función para manejar notificaciones en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

// Notificaciones Locales
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configura la función para manejar notificaciones en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Determina la ruta inicial
  final user = FirebaseAuth.instance.currentUser;
  String initialRoute;

  if (user != null) {
    final email = user.email ?? '';
    print('Usuario autenticado: $email');
    if (email.endsWith('@keiko.com')) {
      initialRoute = '/admin_dashboard';
    } else {
      initialRoute = '/home';
    }
  } else {
    print('Usuario no autenticado');
    initialRoute = '/login';
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => HabitNotifier(habitService: FirebaseHabitService())),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    print('Inicializando MyApp con ruta: $initialRoute');
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Flutter App',
          theme: themeProvider.currentTheme,
          initialRoute: initialRoute,
          routes: {
            // Rutas del proyecto keiko
            '/login': (context) => const Login(),
            '/home': (context) => const Home(),

            // Rutas del proyecto de vista admin
            '/admin_dashboard': (context) => AdminDashboard(),
            '/user_management': (context) => UserManagement(),
            '/role_management': (context) => RoleManagement(),
            '/system_logs': (context) => SystemLogs(),
            '/habitspage': (context) => HabitsPage(),
          },
        );
      },
    );
  }
}

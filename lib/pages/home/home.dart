import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_keiko/widgets/bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_keiko/pages/habits/create_habit.dart';
import 'package:flutter_keiko/services/firebase_habit_service.dart';
import 'package:flutter_keiko/models/habit_model.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';
import 'package:flutter_keiko/widgets/monthly_calendar.dart';
import 'package:flutter_keiko/pages/dashboard/dashboard_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/theme/theme_provider.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';
import 'package:flutter_keiko/services/IA/ia_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<List<Habit>>? _habits;
  final int _currentTabIndex = 0;
  final DateTime _selectedDate = DateTime.now();

  final FirebaseHabitService _habitService = FirebaseHabitService();
  final Map<String, DailyRecord> _cachedDailyRecords = {};
  final OpenAIService _openAIService = OpenAIService();

  // Notificacion
  // Esto controla el estado de las notificaciones
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkNotificationPermission();
  }

  void _showAddNoteDialog(String habitId) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Agregar nota"),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(hintText: "Escribe una nota..."),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                final notes = notesController.text;
                _addDailyRecord(habitId, false, notes);
                Navigator.of(context).pop();
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final habits = await _habitService.getActiveHabitsToday();

      for (final habit in habits) {
        final dailyRecord = await _habitService.getDailyRecordByDate(
            userId, habit.id, DateTime.now());

        if (dailyRecord == null) {
          await _addDailyRecord(habit.id, false, null);
        } else {
          _cachedDailyRecords[habit.id] = dailyRecord;
        }
      }

      setState(() {
        _habits = Future.value(habits);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión de Hábitos"),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            Switch(
              value: themeProvider.isDarkTheme,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Hábitos"),
              Tab(text: "Calendario"),
              Tab(text: "Dashboard"),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/image/fond-home1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildHabitView(),
                      _buildCalendarView(),
                      const DashboardPage(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildHabitView() {
    return FutureBuilder<List<Habit>>(
      future: _habits,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar los hábitos"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay hábitos creados hoy"));
        }

        final habits = snapshot.data!;
        return ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(habit.color),
                  child: Text(habit.emoji),
                ),
                title: Text(habit.name),
                subtitle: Text(habit.category),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.note_add),
                      onPressed: () {
                        _showAddNoteDialog(habit.id);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.lightbulb),
                      onPressed: () async {
                        // Construir un resumen del hábito
                        final habitName = (habit.name);
                        final habitDescription = habit.description != null
                            ? (habit.description)
                            : 'Sin descripcion';
                        final startDate = habit.startDate != null
                            ? 'comenzo el ${habit.startDate!.toLocal()}'
                            : 'sin fecha de inicio';
                        final endDate = habit.endDate != null
                            ? 'y termina el ${habit.endDate!.toLocal()}'
                            : 'sin fecha de termino';

                        // Crear un texto completo para enviar a OpenAI
                        final habitSummary =
                            '$habitName: $habitDescription, $startDate $endDate.';

                        // Llamar al servicio con el resumen
                        final message = await _openAIService
                            .getMotivationalMessage(habitSummary);

                        final decodedMessage =
                            const Utf8Decoder().convert(message.runes.toList());

                        // Mostrar el diálogo con la motivación generada
                        _showMotivationDialog(habit.name, decodedMessage);
                      },
                    ),
                    StatefulBuilder(
                      builder: (context, setState) {
                        final dailyRecord = _cachedDailyRecords[habit.id];

                        return Checkbox(
                          value: dailyRecord?.isCompleted ?? false,
                          onChanged: (bool? value) async {
                            if (value != null) {
                              setState(() {
                                dailyRecord?.isCompleted = value;
                              });
                              await _addDailyRecord(
                                  habit.id, value, dailyRecord?.notes);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Mostrar diálogo con motivación
  void _showMotivationDialog(String habitName, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Motivación para $habitName'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> _addDailyRecord(
      String habitId, bool completed, String? notes) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Check if a record already exists for today
    final existingRecord = _cachedDailyRecords[habitId];
    if (existingRecord != null && isSameDay(existingRecord.date!, now)) {
      // Update the existing record
      final updatedRecord = existingRecord.copyWith(
        isCompleted: completed,
        notes: notes ?? existingRecord.notes,
      );
      _cachedDailyRecords[habitId] = updatedRecord;

      await _habitService.updateDailyRecord(
          userId, habitId, updatedRecord.isCompleted, updatedRecord.notes);
      // Actualizar el registro diario en HabitNotifier
      Provider.of<HabitNotifier>(context, listen: false)
          .addDailyRecord(updatedRecord);
    } else {
      // Create a new record
      final newDailyRecord = DailyRecord(
        habitId: habitId,
        date: startOfDay,
        isCompleted: completed,
        notes: notes ?? "",
      );

      _cachedDailyRecords[habitId] = newDailyRecord;

      await _habitService.addDailyRecord(
          userId, habitId, newDailyRecord.isCompleted, newDailyRecord.notes);
      Provider.of<HabitNotifier>(context, listen: false)
          .addDailyRecord(newDailyRecord);
    }

    // Recargar datos para que el calendario esté actualizado
    Provider.of<HabitNotifier>(context, listen: false).loadAllData();

    setState(() {});
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const CreateHabitPage(),
        ).then((_) {
          _loadData();
        });
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _buildCalendarView() {
    return MonthlyCalendar(
      habitService: _habitService,
      selectedDate: _selectedDate,
    );
  }

  // Notificaciones para usuario ---------------------------------------------

  Future<void> _checkNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permisos para las notificaciones
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Obtener el token FCM
      String? token = await messaging.getToken();
      if (token != null) {
        // Obtener el userId actual del usuario autenticado
        String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        if (userId.isNotEmpty) {
          // Actualizar o guardar el token en el documento del usuario
          await FirebaseFirestore.instance
              .doc("usuarios/$userId")
              .update({"token": token});
          print("Token actualizado para el usuario $userId");
          print("Ahora el token es: ");
          print(token);
        } else {
          print("Error: El usuario no está autenticado.");
        }
      }
    }
  }

  Future<void> _showNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails("channel_id", "channel_name",
            importance: Importance.high);

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      "Recordatorio de hábitos",
      "No olvides realizar tus hábitos hoy.",
      notificationDetails,
    );
  }

}
